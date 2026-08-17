import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/utils/hash_util.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

import '../domain/call_payment_models.dart';
import '../domain/call_payment_repositories.dart';

typedef CallPaymentClock = DateTime Function();

abstract interface class CallPaymentTokenSender {
  Future<CashuPreparedSend> prepareSend({
    required CashuMintUrl mintUrl,
    required CashuAmount amount,
    String? memo,
  });
}

abstract interface class CallPaymentTransferGateway {
  Future<OKEvent> send({
    required String receiverPubkey,
    required CallPaymentEventPayload payload,
  });
}

final class CallPaymentInitialPaymentRequest {
  const CallPaymentInitialPaymentRequest({
    required this.owner,
    required this.callId,
    required this.peerPubkey,
    required this.callType,
    required this.mintUrl,
    required this.amountSats,
    required this.priceSatsPerMinute,
    required this.billingPeriodSeconds,
    required this.maxSpendSats,
  });

  final CashuAccountId owner;
  final String callId;
  final String peerPubkey;
  final CallPaymentCallType callType;
  final CashuMintUrl mintUrl;
  final int amountSats;
  final int priceSatsPerMinute;
  final int billingPeriodSeconds;
  final int maxSpendSats;
}

final class CallPaymentInitialPaymentResult {
  const CallPaymentInitialPaymentResult({
    required this.session,
    required this.installment,
    required this.okEvent,
  });

  final CallPaymentSession session;
  final CallPaymentInstallment installment;
  final OKEvent okEvent;
}

final class CallPaymentInitialPaymentService {
  CallPaymentInitialPaymentService({
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

  Future<CallPaymentInitialPaymentResult> prepareAndSend(
    CallPaymentInitialPaymentRequest request,
  ) async {
    _validateRequest(request);
    final now = _clock();
    final paymentSessionId = '${request.callId}:payer';
    final session = CallPaymentSession(
      owner: request.owner,
      callId: request.callId,
      peerPubkey: request.peerPubkey,
      direction: CallPaymentCallDirection.outgoing,
      role: CallPaymentRole.payer,
      callType: request.callType,
      status: CallPaymentSessionStatus.preparingInitialPayment,
      mintUrl: request.mintUrl,
      priceSatsPerMinute: request.priceSatsPerMinute,
      billingPeriodSeconds: request.billingPeriodSeconds,
      maxSpendSats: request.maxSpendSats,
      connectedDurationSeconds: 0,
      chargedSats: 0,
      refundedSats: 0,
      createdAt: now,
      updatedAt: now,
    );
    await _sessionRepository.save(session);

    var installment = CallPaymentInstallment(
      owner: request.owner,
      callId: request.callId,
      paymentSessionId: paymentSessionId,
      sequence: 1,
      purpose: CallPaymentPurpose.initial,
      direction: CallPaymentTransferDirection.sent,
      amountSats: request.amountSats,
      mintUrl: request.mintUrl,
      status: CallPaymentInstallmentStatus.created,
      coversFromSecond: 0,
      coversToSecond: request.billingPeriodSeconds,
      createdAt: now,
      updatedAt: now,
    );
    await _installmentRepository.save(installment);

    final prepared = await _tokenSender.prepareSend(
      mintUrl: request.mintUrl,
      amount: CashuAmount.positiveSats(request.amountSats),
      memo: 'noscall paid call ${request.callId} initial',
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
      sequence: installment.sequence,
      purpose: installment.purpose,
      callType: request.callType,
      payerPubkey: request.owner.value,
      payeePubkey: request.peerPubkey,
      mintUrl: request.mintUrl,
      amountSats: request.amountSats,
      billingPeriodSeconds: request.billingPeriodSeconds,
      coversFromSecond: installment.coversFromSecond,
      coversToSecond: installment.coversToSecond,
      tokenHash: tokenHash,
      createdAt: preparedAt,
      expiresAt: preparedAt.add(
        Duration(seconds: request.billingPeriodSeconds),
      ),
      token: prepared.token,
    );
    final okEvent = await _gateway.send(
      receiverPubkey: request.peerPubkey,
      payload: payload,
    );
    final sentAt = _clock();
    final status = okEvent.status
        ? CallPaymentInstallmentStatus.sent
        : CallPaymentInstallmentStatus.failed;
    installment = installment.copyWith(
      status: status,
      sentAt: okEvent.status ? sentAt : null,
      updatedAt: sentAt,
      errorCode: okEvent.status ? null : 'payment_transfer_send_failed',
      clearErrorCode: okEvent.status,
    );
    await _installmentRepository.save(installment);

    final updatedSession = session.copyWith(
      status: okEvent.status
          ? CallPaymentSessionStatus.initialPaymentSent
          : CallPaymentSessionStatus.paymentFailed,
      chargedSats: okEvent.status ? request.amountSats : 0,
      updatedAt: sentAt,
    );
    await _sessionRepository.save(updatedSession);

    return CallPaymentInitialPaymentResult(
      session: updatedSession,
      installment: installment,
      okEvent: okEvent,
    );
  }

  void _validateRequest(CallPaymentInitialPaymentRequest request) {
    if (request.callId.isEmpty || request.peerPubkey.isEmpty) {
      throw ArgumentError('Initial payment requires call id and peer pubkey');
    }
    if (request.amountSats <= 0 ||
        request.priceSatsPerMinute <= 0 ||
        request.billingPeriodSeconds <= 0 ||
        request.maxSpendSats < request.amountSats) {
      throw ArgumentError('Initial payment request has invalid amounts');
    }
  }
}
