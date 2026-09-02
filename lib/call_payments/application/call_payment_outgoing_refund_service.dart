import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/utils/hash_util.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

import '../domain/call_payment_models.dart';
import '../domain/call_payment_repositories.dart';
import 'call_payment_initial_payment_service.dart';

final class CallPaymentOutgoingRefundRequest {
  const CallPaymentOutgoingRefundRequest({
    required this.owner,
    required this.callId,
  });

  final CashuAccountId owner;
  final String callId;
}

final class CallPaymentOutgoingRefundResult {
  const CallPaymentOutgoingRefundResult({
    required this.session,
    required this.installments,
  });

  final CallPaymentSession session;
  final List<CallPaymentInstallment> installments;

  int get refundedSats => installments
      .where(
        (installment) =>
            installment.status == CallPaymentInstallmentStatus.sent,
      )
      .fold(0, (total, installment) => total + installment.amountSats);
}

final class CallPaymentOutgoingRefundService {
  CallPaymentOutgoingRefundService({
    required CallPaymentSessionRepository sessionRepository,
    required CallPaymentInstallmentRepository installmentRepository,
    required CallPaymentTokenSender tokenSender,
    required CallPaymentTransferGateway gateway,
    CallPaymentClock? clock,
  }) : _sessionRepository = sessionRepository,
       _installmentRepository = installmentRepository,
       _tokenSender = tokenSender,
       _gateway = gateway,
       _clock = clock ?? DateTime.now;

  final CallPaymentSessionRepository _sessionRepository;
  final CallPaymentInstallmentRepository _installmentRepository;
  final CallPaymentTokenSender _tokenSender;
  final CallPaymentTransferGateway _gateway;
  final CallPaymentClock _clock;

  Future<CallPaymentOutgoingRefundResult> prepareAndSend(
    CallPaymentOutgoingRefundRequest request,
  ) async {
    if (request.callId.isEmpty) {
      throw ArgumentError('Outgoing payment refund requires call id');
    }
    final loadedSession = await _sessionRepository.find(
      request.owner,
      request.callId,
    );
    if (loadedSession == null) {
      throw StateError('Payment session does not exist for outgoing refund');
    }
    var session = loadedSession;
    _validateSession(session);

    final installments = await _installmentRepository.listForCall(
      owner: request.owner,
      callId: request.callId,
    );
    final alreadyRefundedSequences = installments
        .where(
          (installment) =>
              installment.direction == CallPaymentTransferDirection.sent &&
              installment.purpose == CallPaymentPurpose.refund &&
              installment.status != CallPaymentInstallmentStatus.failed,
        )
        .map((installment) => installment.sequence)
        .toSet();
    final refundableInstallments = installments
        .where(
          (installment) => _isRefundableInstallment(
            session: session,
            installment: installment,
            alreadyRefundedSequences: alreadyRefundedSequences,
          ),
        )
        .toList(growable: false);

    final sentRefunds = <CallPaymentInstallment>[];
    for (var index = 0; index < refundableInstallments.length; index++) {
      final installment = refundableInstallments[index];
      final result = await _prepareAndSendInstallment(
        session,
        installment,
        completeAfterSuccess: index == refundableInstallments.length - 1,
      );
      sentRefunds.add(result.installment);
      session = result.session;
      if (result.installment.status != CallPaymentInstallmentStatus.sent) {
        break;
      }
    }

    return CallPaymentOutgoingRefundResult(
      session: session,
      installments: List.unmodifiable(sentRefunds),
    );
  }

  void _validateSession(CallPaymentSession session) {
    if (session.role != CallPaymentRole.payee) {
      throw StateError('Only payee sessions can send payment refunds');
    }
    if (session.status != CallPaymentSessionStatus.refundPending) {
      throw StateError('Payment session is not pending refund');
    }
    if (session.chargedSats <= session.refundedSats) {
      throw StateError('Payment session has no refundable balance');
    }
  }

  bool _isRefundableInstallment({
    required CallPaymentSession session,
    required CallPaymentInstallment installment,
    required Set<int> alreadyRefundedSequences,
  }) {
    if (installment.direction != CallPaymentTransferDirection.received ||
        installment.purpose == CallPaymentPurpose.refund ||
        installment.status != CallPaymentInstallmentStatus.claimed ||
        alreadyRefundedSequences.contains(installment.sequence)) {
      return false;
    }
    if (session.connectedAt == null) return true;
    return session.connectedDurationSeconds < installment.coversFromSecond;
  }

  Future<({CallPaymentSession session, CallPaymentInstallment installment})>
  _prepareAndSendInstallment(
    CallPaymentSession session,
    CallPaymentInstallment original, {
    required bool completeAfterSuccess,
  }) async {
    final now = _clock();
    var refundInstallment = CallPaymentInstallment(
      owner: session.owner,
      callId: session.callId,
      paymentSessionId: original.paymentSessionId,
      sequence: original.sequence,
      purpose: CallPaymentPurpose.refund,
      direction: CallPaymentTransferDirection.sent,
      amountSats: original.amountSats,
      mintUrl: original.mintUrl,
      status: CallPaymentInstallmentStatus.created,
      coversFromSecond: original.coversFromSecond,
      coversToSecond: original.coversToSecond,
      createdAt: now,
      updatedAt: now,
    );
    await _installmentRepository.save(refundInstallment);

    final prepared = await _tokenSender.prepareSend(
      mintUrl: original.mintUrl,
      amount: CashuAmount.positiveSats(original.amountSats),
      memo: 'noscall paid call ${session.callId} refund ${original.sequence}',
    );
    final tokenHash = HashUtil.sha256String(prepared.token);
    final preparedAt = _clock();
    refundInstallment = refundInstallment.copyWith(
      walletOperationId: prepared.operationId,
      tokenHash: tokenHash,
      status: CallPaymentInstallmentStatus.prepared,
      updatedAt: preparedAt,
      clearErrorCode: true,
    );
    await _installmentRepository.save(refundInstallment);

    final payload = CallPaymentEventPayload(
      type: CallPaymentEventType.refund,
      callId: session.callId,
      paymentSessionId: original.paymentSessionId,
      sequence: original.sequence,
      purpose: CallPaymentPurpose.refund,
      callType: session.callType,
      payerPubkey: session.peerPubkey,
      payeePubkey: session.owner.value,
      mintUrl: original.mintUrl,
      amountSats: original.amountSats,
      billingPeriodSeconds: session.billingPeriodSeconds,
      coversFromSecond: original.coversFromSecond,
      coversToSecond: original.coversToSecond,
      tokenHash: tokenHash,
      createdAt: preparedAt,
      expiresAt: preparedAt.add(
        Duration(seconds: session.billingPeriodSeconds),
      ),
      token: prepared.token,
    );
    final okEvent = await _gateway.send(
      receiverPubkey: session.peerPubkey,
      payload: payload,
    );
    final sentAt = _clock();
    refundInstallment = refundInstallment.copyWith(
      status: okEvent.status
          ? CallPaymentInstallmentStatus.sent
          : CallPaymentInstallmentStatus.failed,
      sentAt: okEvent.status ? sentAt : null,
      refundedAt: okEvent.status ? sentAt : null,
      updatedAt: sentAt,
      errorCode: okEvent.status ? null : 'payment_refund_send_failed',
      clearErrorCode: okEvent.status,
    );
    await _installmentRepository.save(refundInstallment);

    if (!okEvent.status) {
      return (session: session, installment: refundInstallment);
    }

    final refundedSats = _refundedSatsAfter(session, original.amountSats);
    final updatedSession = session.copyWith(
      status: completeAfterSuccess
          ? CallPaymentSessionStatus.completed
          : CallPaymentSessionStatus.refundPending,
      refundedSats: refundedSats,
      updatedAt: sentAt,
    );
    await _sessionRepository.save(updatedSession);

    return (session: updatedSession, installment: refundInstallment);
  }

  int _refundedSatsAfter(CallPaymentSession session, int amountSats) {
    final refundedSats = session.refundedSats + amountSats;
    return refundedSats > session.chargedSats
        ? session.chargedSats
        : refundedSats;
  }
}
