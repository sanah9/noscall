import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/utils/hash_util.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

import '../domain/call_payment_models.dart';
import '../domain/call_payment_repositories.dart';
import 'call_payment_initial_payment_service.dart';

final class CallPaymentTopUpRequest {
  const CallPaymentTopUpRequest({required this.owner, required this.callId});

  final CashuAccountId owner;
  final String callId;
}

final class CallPaymentTopUpResult {
  const CallPaymentTopUpResult({
    required this.session,
    required this.installment,
    required this.okEvent,
  });

  final CallPaymentSession session;
  final CallPaymentInstallment installment;
  final OKEvent okEvent;
}

final class CallPaymentTopUpService {
  CallPaymentTopUpService({
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

  Future<CallPaymentTopUpResult> prepareAndSend(
    CallPaymentTopUpRequest request,
  ) async {
    if (request.callId.isEmpty) {
      throw ArgumentError('Top-up payment requires call id');
    }
    final session = await _sessionRepository.find(
      request.owner,
      request.callId,
    );
    if (session == null) {
      throw StateError('Payment session does not exist for top-up');
    }
    if (session.role != CallPaymentRole.payer) {
      throw StateError('Only payer sessions can send top-up payments');
    }

    final amountSats = _periodAmountSats(session);
    if (session.chargedSats + amountSats > session.maxSpendSats) {
      throw StateError('Payment session max spend reached');
    }

    final installments = await _installmentRepository.listForCall(
      owner: request.owner,
      callId: request.callId,
    );
    final nextSequence = _nextSequence(installments);
    final coversFromSecond = _nextCoverageStart(installments);
    final coversToSecond = coversFromSecond + session.billingPeriodSeconds;
    final paymentSessionId = _paymentSessionId(session, installments);
    final now = _clock();

    await _sessionRepository.save(
      session.copyWith(
        status: CallPaymentSessionStatus.toppingUp,
        updatedAt: now,
      ),
    );

    var installment = CallPaymentInstallment(
      owner: request.owner,
      callId: request.callId,
      paymentSessionId: paymentSessionId,
      sequence: nextSequence,
      purpose: CallPaymentPurpose.topUp,
      direction: CallPaymentTransferDirection.sent,
      amountSats: amountSats,
      mintUrl: session.mintUrl,
      status: CallPaymentInstallmentStatus.created,
      coversFromSecond: coversFromSecond,
      coversToSecond: coversToSecond,
      createdAt: now,
      updatedAt: now,
    );
    await _installmentRepository.save(installment);

    final prepared = await _tokenSender.prepareSend(
      mintUrl: session.mintUrl,
      amount: CashuAmount.positiveSats(amountSats),
      memo: 'noscall paid call ${request.callId} top-up $nextSequence',
    );
    final tokenHash = HashUtil.sha256String(prepared.token);
    final preparedAt = _clock();
    installment = installment.copyWith(
      walletOperationId: prepared.operationId,
      tokenHash: tokenHash,
      status: CallPaymentInstallmentStatus.prepared,
      updatedAt: preparedAt,
      clearErrorCode: true,
    );
    await _installmentRepository.save(installment);

    final payload = CallPaymentEventPayload(
      type: CallPaymentEventType.transfer,
      callId: request.callId,
      paymentSessionId: paymentSessionId,
      sequence: nextSequence,
      purpose: CallPaymentPurpose.topUp,
      callType: session.callType,
      payerPubkey: request.owner.value,
      payeePubkey: session.peerPubkey,
      mintUrl: session.mintUrl,
      amountSats: amountSats,
      billingPeriodSeconds: session.billingPeriodSeconds,
      coversFromSecond: coversFromSecond,
      coversToSecond: coversToSecond,
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
    installment = installment.copyWith(
      status: okEvent.status
          ? CallPaymentInstallmentStatus.sent
          : CallPaymentInstallmentStatus.failed,
      sentAt: okEvent.status ? sentAt : null,
      updatedAt: sentAt,
      errorCode: okEvent.status ? null : 'payment_top_up_send_failed',
      clearErrorCode: okEvent.status,
    );
    await _installmentRepository.save(installment);

    final updatedSession = session.copyWith(
      status: okEvent.status
          ? CallPaymentSessionStatus.connected
          : CallPaymentSessionStatus.paymentFailed,
      chargedSats: okEvent.status
          ? session.chargedSats + amountSats
          : session.chargedSats,
      updatedAt: sentAt,
    );
    await _sessionRepository.save(updatedSession);

    return CallPaymentTopUpResult(
      session: updatedSession,
      installment: installment,
      okEvent: okEvent,
    );
  }

  int _periodAmountSats(CallPaymentSession session) {
    return (session.priceSatsPerMinute * session.billingPeriodSeconds / 60)
        .ceil();
  }

  int _nextSequence(List<CallPaymentInstallment> installments) {
    if (installments.isEmpty) return 1;
    return installments
            .map((installment) => installment.sequence)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  int _nextCoverageStart(List<CallPaymentInstallment> installments) {
    if (installments.isEmpty) return 0;
    return installments
        .map((installment) => installment.coversToSecond)
        .reduce((a, b) => a > b ? a : b);
  }

  String _paymentSessionId(
    CallPaymentSession session,
    List<CallPaymentInstallment> installments,
  ) {
    if (installments.isNotEmpty) return installments.first.paymentSessionId;
    return '${session.callId}:payer';
  }
}
