import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/utils/hash_util.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';

import '../domain/call_payment_models.dart';
import '../domain/call_payment_repositories.dart';
import 'call_payment_incoming_transfer_service.dart';
import 'call_payment_initial_payment_service.dart';

final class CallPaymentRefundRequest {
  const CallPaymentRefundRequest({
    required this.owner,
    required this.senderPubkey,
    required this.payload,
  });

  final CashuAccountId owner;
  final String senderPubkey;
  final CallPaymentEventPayload payload;
}

final class CallPaymentRefundResult {
  const CallPaymentRefundResult({
    required this.session,
    required this.installment,
  });

  final CallPaymentSession session;
  final CallPaymentInstallment installment;
}

final class CallPaymentRefundService {
  CallPaymentRefundService({
    required CallPaymentSessionRepository sessionRepository,
    required CallPaymentInstallmentRepository installmentRepository,
    required CallPaymentTokenReceiver tokenReceiver,
    CallPaymentClock? clock,
  }) : _sessionRepository = sessionRepository,
       _installmentRepository = installmentRepository,
       _tokenReceiver = tokenReceiver,
       _clock = clock ?? DateTime.now;

  final CallPaymentSessionRepository _sessionRepository;
  final CallPaymentInstallmentRepository _installmentRepository;
  final CallPaymentTokenReceiver _tokenReceiver;
  final CallPaymentClock _clock;

  Future<CallPaymentRefundResult> receive(
    CallPaymentRefundRequest request,
  ) async {
    _validateRequest(request);
    final payload = request.payload;
    final existingInstallment = await _installmentRepository.find(
      owner: request.owner,
      callId: payload.callId,
      sequence: payload.sequence,
      purpose: CallPaymentPurpose.refund,
      direction: CallPaymentTransferDirection.received,
    );
    if (existingInstallment != null) {
      final session = await _loadSession(request);
      return CallPaymentRefundResult(
        session: session,
        installment: existingInstallment,
      );
    }

    final session = await _loadSession(request);
    _validateSession(session, request);
    await _loadMatchingOriginalInstallment(session, payload);

    final received = await _tokenReceiver.receive(payload.token!);
    if (received.amount.value != payload.amountSats) {
      throw ArgumentError('Payment refund token amount does not match');
    }
    final now = _clock();
    final installment = CallPaymentInstallment(
      owner: request.owner,
      callId: payload.callId,
      paymentSessionId: payload.paymentSessionId,
      sequence: payload.sequence,
      purpose: CallPaymentPurpose.refund,
      direction: CallPaymentTransferDirection.received,
      amountSats: payload.amountSats,
      mintUrl: payload.mintUrl,
      walletOperationId: received.operationId,
      tokenHash: payload.tokenHash,
      status: CallPaymentInstallmentStatus.refunded,
      coversFromSecond: payload.coversFromSecond,
      coversToSecond: payload.coversToSecond,
      createdAt: now,
      claimedAt: now,
      refundedAt: now,
      updatedAt: now,
    );
    await _installmentRepository.save(installment);

    final refundedSats = _refundedSatsAfter(session, payload.amountSats);
    final updatedSession = session.copyWith(
      status: refundedSats >= session.chargedSats
          ? CallPaymentSessionStatus.completed
          : CallPaymentSessionStatus.refundPending,
      refundedSats: refundedSats,
      updatedAt: now,
    );
    await _sessionRepository.save(updatedSession);

    return CallPaymentRefundResult(
      session: updatedSession,
      installment: installment,
    );
  }

  void _validateRequest(CallPaymentRefundRequest request) {
    final payload = request.payload;
    if (payload.type != CallPaymentEventType.refund) {
      throw ArgumentError('Payment refund service requires a refund payload');
    }
    if (payload.purpose != CallPaymentPurpose.refund) {
      throw ArgumentError('Payment refund payload must use refund purpose');
    }
    if (payload.payerPubkey != request.owner.value ||
        payload.payeePubkey != request.senderPubkey) {
      throw ArgumentError('Payment refund participants do not match');
    }
    if (payload.token == null || payload.token!.isEmpty) {
      throw ArgumentError('Payment refund must include a token');
    }
    if (HashUtil.sha256String(payload.token!) != payload.tokenHash) {
      throw ArgumentError('Payment refund token hash does not match');
    }
    if (payload.amountSats <= 0) {
      throw ArgumentError('Payment refund amount must be positive');
    }
  }

  Future<CallPaymentSession> _loadSession(
    CallPaymentRefundRequest request,
  ) async {
    final session = await _sessionRepository.find(
      request.owner,
      request.payload.callId,
    );
    if (session == null) {
      throw StateError('Payment session does not exist for refund');
    }
    return session;
  }

  void _validateSession(
    CallPaymentSession session,
    CallPaymentRefundRequest request,
  ) {
    final payload = request.payload;
    if (session.role != CallPaymentRole.payer ||
        session.peerPubkey != request.senderPubkey) {
      throw StateError('Payment refund does not match payer session');
    }
    if (session.callType != payload.callType ||
        session.mintUrl != payload.mintUrl) {
      throw ArgumentError('Payment refund session details do not match');
    }
    if (session.chargedSats <= 0) {
      throw StateError('Payment refund requires a charged session');
    }
  }

  Future<CallPaymentInstallment> _loadMatchingOriginalInstallment(
    CallPaymentSession session,
    CallPaymentEventPayload payload,
  ) async {
    final installments = await _installmentRepository.listForCall(
      owner: session.owner,
      callId: session.callId,
    );
    final matching = installments.where(
      (installment) =>
          installment.sequence == payload.sequence &&
          installment.paymentSessionId == payload.paymentSessionId &&
          installment.purpose != CallPaymentPurpose.refund &&
          installment.direction == CallPaymentTransferDirection.sent &&
          installment.walletOperationId != null &&
          installment.mintUrl == payload.mintUrl &&
          installment.amountSats == payload.amountSats &&
          installment.coversFromSecond == payload.coversFromSecond &&
          installment.coversToSecond == payload.coversToSecond &&
          switch (installment.status) {
            CallPaymentInstallmentStatus.prepared ||
            CallPaymentInstallmentStatus.sent ||
            CallPaymentInstallmentStatus.claimed ||
            CallPaymentInstallmentStatus.reclaimable ||
            CallPaymentInstallmentStatus.unknown => true,
            _ => false,
          },
    );
    if (matching.isEmpty) {
      throw StateError('Payment refund does not match a paid installment');
    }
    return matching.first;
  }

  int _refundedSatsAfter(CallPaymentSession session, int amountSats) {
    final refundedSats = session.refundedSats + amountSats;
    return refundedSats > session.chargedSats
        ? session.chargedSats
        : refundedSats;
  }
}
