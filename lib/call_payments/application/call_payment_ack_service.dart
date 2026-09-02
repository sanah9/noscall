import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';

import '../domain/call_payment_models.dart';
import '../domain/call_payment_repositories.dart';
import 'call_payment_initial_payment_service.dart';

final class CallPaymentAckRequest {
  const CallPaymentAckRequest({
    required this.owner,
    required this.senderPubkey,
    required this.payload,
  });

  final CashuAccountId owner;
  final String senderPubkey;
  final CallPaymentEventPayload payload;
}

final class CallPaymentAckResult {
  const CallPaymentAckResult({
    required this.session,
    required this.installment,
  });

  final CallPaymentSession session;
  final CallPaymentInstallment installment;
}

final class CallPaymentAckService {
  CallPaymentAckService({
    required CallPaymentSessionRepository sessionRepository,
    required CallPaymentInstallmentRepository installmentRepository,
    CallPaymentClock? clock,
  }) : _sessionRepository = sessionRepository,
       _installmentRepository = installmentRepository,
       _clock = clock ?? DateTime.now;

  final CallPaymentSessionRepository _sessionRepository;
  final CallPaymentInstallmentRepository _installmentRepository;
  final CallPaymentClock _clock;

  Future<CallPaymentAckResult> apply(CallPaymentAckRequest request) async {
    _validateRequest(request);
    final payload = request.payload;
    final installment = await _installmentRepository.find(
      owner: request.owner,
      callId: payload.callId,
      sequence: payload.sequence,
      purpose: payload.purpose,
      direction: CallPaymentTransferDirection.sent,
    );
    if (installment == null) {
      throw StateError('Payment installment does not exist for ack');
    }
    final session = await _sessionRepository.find(
      request.owner,
      payload.callId,
    );
    if (session == null) {
      throw StateError('Payment session does not exist for ack');
    }
    _validateSession(session, request);
    _validateInstallment(installment, payload);

    final now = _clock();
    final updatedInstallment = installment.copyWith(
      status: CallPaymentInstallmentStatus.claimed,
      claimedAt: installment.claimedAt ?? now,
      updatedAt: now,
      clearErrorCode: true,
    );
    await _installmentRepository.save(updatedInstallment);

    final updatedSession = session.copyWith(
      status: _sessionStatusAfterAck(session, payload),
      updatedAt: now,
    );
    await _sessionRepository.save(updatedSession);

    return CallPaymentAckResult(
      session: updatedSession,
      installment: updatedInstallment,
    );
  }

  void _validateRequest(CallPaymentAckRequest request) {
    final payload = request.payload;
    if (payload.type != CallPaymentEventType.ack) {
      throw ArgumentError('Payment ack service requires an ack payload');
    }
    if (payload.payerPubkey != request.owner.value ||
        payload.payeePubkey != request.senderPubkey) {
      throw ArgumentError('Payment ack participants do not match');
    }
  }

  void _validateSession(
    CallPaymentSession session,
    CallPaymentAckRequest request,
  ) {
    final payload = request.payload;
    if (session.role != CallPaymentRole.payer ||
        session.direction != CallPaymentCallDirection.outgoing ||
        session.peerPubkey != request.senderPubkey ||
        session.callType != payload.callType ||
        session.mintUrl != payload.mintUrl) {
      throw StateError('Payment ack does not match payer session');
    }
  }

  void _validateInstallment(
    CallPaymentInstallment installment,
    CallPaymentEventPayload payload,
  ) {
    if (installment.paymentSessionId != payload.paymentSessionId ||
        installment.amountSats != payload.amountSats ||
        installment.mintUrl != payload.mintUrl ||
        installment.tokenHash != payload.tokenHash ||
        installment.coversFromSecond != payload.coversFromSecond ||
        installment.coversToSecond != payload.coversToSecond) {
      throw ArgumentError('Payment ack does not match sent installment');
    }
    switch (installment.status) {
      case CallPaymentInstallmentStatus.prepared:
      case CallPaymentInstallmentStatus.sent:
      case CallPaymentInstallmentStatus.claimed:
      case CallPaymentInstallmentStatus.reclaimable:
      case CallPaymentInstallmentStatus.unknown:
        return;
      case _:
        throw StateError('Payment installment cannot accept ack');
    }
  }

  CallPaymentSessionStatus _sessionStatusAfterAck(
    CallPaymentSession session,
    CallPaymentEventPayload payload,
  ) {
    if (payload.purpose == CallPaymentPurpose.topUp ||
        session.status == CallPaymentSessionStatus.connected) {
      return CallPaymentSessionStatus.connected;
    }
    return CallPaymentSessionStatus.ringing;
  }
}
