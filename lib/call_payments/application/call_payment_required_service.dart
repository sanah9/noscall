import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';

import '../domain/call_payment_models.dart';
import '../domain/call_payment_repositories.dart';
import 'call_payment_initial_payment_service.dart';

final class CallPaymentRequiredRequest {
  const CallPaymentRequiredRequest({
    required this.owner,
    required this.senderPubkey,
    required this.payload,
  });

  final CashuAccountId owner;
  final String senderPubkey;
  final CallPaymentEventPayload payload;
}

final class CallPaymentRequiredResult {
  const CallPaymentRequiredResult({required this.session});

  final CallPaymentSession session;
}

final class CallPaymentRequiredService {
  CallPaymentRequiredService({
    required CallPaymentSessionRepository sessionRepository,
    required CallPaymentInstallmentRepository installmentRepository,
    CallPaymentClock? clock,
  }) : _sessionRepository = sessionRepository,
       _installmentRepository = installmentRepository,
       _clock = clock ?? DateTime.now;

  final CallPaymentSessionRepository _sessionRepository;
  final CallPaymentInstallmentRepository _installmentRepository;
  final CallPaymentClock _clock;

  Future<CallPaymentRequiredResult> apply(
    CallPaymentRequiredRequest request,
  ) async {
    _validateRequest(request);
    final payload = request.payload;
    final session = await _sessionRepository.find(
      request.owner,
      payload.callId,
    );
    if (session == null) {
      throw StateError('Payment session does not exist for required event');
    }
    _validateSession(session, request);

    final installments = await _installmentRepository.listForCall(
      owner: request.owner,
      callId: payload.callId,
    );
    final updatedSession = session.copyWith(
      status: _statusAfterRequired(installments),
      updatedAt: _clock(),
    );
    await _sessionRepository.save(updatedSession);

    return CallPaymentRequiredResult(session: updatedSession);
  }

  void _validateRequest(CallPaymentRequiredRequest request) {
    final payload = request.payload;
    if (payload.type != CallPaymentEventType.required) {
      throw ArgumentError(
        'Payment required service requires a required payload',
      );
    }
    if (payload.payerPubkey != request.owner.value ||
        payload.payeePubkey != request.senderPubkey) {
      throw ArgumentError('Payment required participants do not match');
    }
    if (payload.token != null) {
      throw ArgumentError('Payment required payload must not include a token');
    }
    if (payload.amountSats <= 0 || payload.billingPeriodSeconds <= 0) {
      throw ArgumentError('Payment required payload has invalid amounts');
    }
    if (payload.sequence != 1 ||
        payload.purpose != CallPaymentPurpose.initial ||
        payload.coversFromSecond != 0 ||
        payload.coversToSecond != payload.billingPeriodSeconds) {
      throw ArgumentError('Payment required payload must match initial period');
    }
  }

  void _validateSession(
    CallPaymentSession session,
    CallPaymentRequiredRequest request,
  ) {
    final payload = request.payload;
    if (session.role != CallPaymentRole.payer ||
        session.direction != CallPaymentCallDirection.outgoing ||
        session.peerPubkey != request.senderPubkey ||
        session.callType != payload.callType ||
        session.mintUrl != payload.mintUrl ||
        session.billingPeriodSeconds != payload.billingPeriodSeconds ||
        _periodAmountSats(session) != payload.amountSats) {
      throw StateError('Payment required event does not match payer session');
    }
  }

  int _periodAmountSats(CallPaymentSession session) {
    return (session.priceSatsPerMinute * session.billingPeriodSeconds / 60)
        .ceil();
  }

  CallPaymentSessionStatus _statusAfterRequired(
    List<CallPaymentInstallment> installments,
  ) {
    final sentInstallments = installments.where(
      (installment) =>
          installment.direction == CallPaymentTransferDirection.sent,
    );
    if (sentInstallments.any(
      (installment) =>
          installment.status == CallPaymentInstallmentStatus.claimed,
    )) {
      return CallPaymentSessionStatus.refundPending;
    }
    if (sentInstallments.any(_isReclaimCandidate)) {
      return CallPaymentSessionStatus.reclaimPending;
    }
    return CallPaymentSessionStatus.paymentFailed;
  }

  bool _isReclaimCandidate(CallPaymentInstallment installment) {
    return switch (installment.status) {
      CallPaymentInstallmentStatus.created ||
      CallPaymentInstallmentStatus.prepared ||
      CallPaymentInstallmentStatus.sent ||
      CallPaymentInstallmentStatus.reclaimable ||
      CallPaymentInstallmentStatus.unknown => true,
      _ => false,
    };
  }
}
