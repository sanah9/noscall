import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

import '../domain/call_payment_models.dart';
import '../domain/call_payment_repositories.dart';
import 'call_payment_initial_payment_service.dart';

abstract interface class CallPaymentTokenReceiver {
  Future<CashuReceiveResult> receive(String encodedToken);
}

final class CallPaymentIncomingTransferRequest {
  const CallPaymentIncomingTransferRequest({
    required this.owner,
    required this.senderPubkey,
    required this.callType,
    required this.payload,
  });

  final CashuAccountId owner;
  final String senderPubkey;
  final CallPaymentCallType callType;
  final CallPaymentEventPayload payload;
}

final class CallPaymentIncomingTransferResult {
  const CallPaymentIncomingTransferResult({
    required this.session,
    required this.installment,
    required this.ackEvent,
  });

  final CallPaymentSession session;
  final CallPaymentInstallment installment;
  final OKEvent ackEvent;
}

final class CallPaymentIncomingTransferService {
  CallPaymentIncomingTransferService({
    required CallPaymentSessionRepository sessionRepository,
    required CallPaymentInstallmentRepository installmentRepository,
    required CallPaymentTokenReceiver tokenReceiver,
    required CallPaymentTransferGateway gateway,
    CallPaymentClock? clock,
  }) : _sessionRepository = sessionRepository,
       _installmentRepository = installmentRepository,
       _tokenReceiver = tokenReceiver,
       _gateway = gateway,
       _clock = clock ?? DateTime.now;

  final CallPaymentSessionRepository _sessionRepository;
  final CallPaymentInstallmentRepository _installmentRepository;
  final CallPaymentTokenReceiver _tokenReceiver;
  final CallPaymentTransferGateway _gateway;
  final CallPaymentClock _clock;

  Future<CallPaymentIncomingTransferResult> receiveAndAck(
    CallPaymentIncomingTransferRequest request,
  ) async {
    _validateRequest(request);
    final payload = request.payload;
    final token = payload.token!;
    final received = await _tokenReceiver.receive(token);
    final now = _clock();
    final session = CallPaymentSession(
      owner: request.owner,
      callId: payload.callId,
      peerPubkey: payload.payerPubkey,
      direction: CallPaymentCallDirection.incoming,
      role: CallPaymentRole.payee,
      callType: request.callType,
      status: CallPaymentSessionStatus.ringing,
      mintUrl: payload.mintUrl,
      priceSatsPerMinute: _priceSatsPerMinute(payload),
      billingPeriodSeconds: payload.billingPeriodSeconds,
      maxSpendSats: payload.amountSats,
      connectedDurationSeconds: 0,
      chargedSats: payload.amountSats,
      refundedSats: 0,
      createdAt: now,
      updatedAt: now,
    );
    await _sessionRepository.save(session);

    var installment = CallPaymentInstallment(
      owner: request.owner,
      callId: payload.callId,
      paymentSessionId: payload.paymentSessionId,
      sequence: payload.sequence,
      purpose: payload.purpose,
      direction: CallPaymentTransferDirection.received,
      amountSats: payload.amountSats,
      mintUrl: payload.mintUrl,
      walletOperationId: received.operationId,
      tokenHash: payload.tokenHash,
      status: CallPaymentInstallmentStatus.claimed,
      coversFromSecond: payload.coversFromSecond,
      coversToSecond: payload.coversToSecond,
      createdAt: now,
      claimedAt: now,
      updatedAt: now,
    );
    await _installmentRepository.save(installment);

    final ackPayload = CallPaymentEventPayload(
      type: CallPaymentEventType.ack,
      callId: payload.callId,
      paymentSessionId: payload.paymentSessionId,
      sequence: payload.sequence,
      purpose: payload.purpose,
      payerPubkey: payload.payerPubkey,
      payeePubkey: request.owner.value,
      mintUrl: payload.mintUrl,
      amountSats: payload.amountSats,
      billingPeriodSeconds: payload.billingPeriodSeconds,
      coversFromSecond: payload.coversFromSecond,
      coversToSecond: payload.coversToSecond,
      tokenHash: payload.tokenHash,
      createdAt: _clock(),
      expiresAt: payload.expiresAt,
    );
    final ackEvent = await _gateway.send(
      receiverPubkey: payload.payerPubkey,
      payload: ackPayload,
    );
    if (!ackEvent.status) {
      installment = installment.copyWith(
        updatedAt: _clock(),
        errorCode: 'payment_ack_send_failed',
      );
      await _installmentRepository.save(installment);
    }

    return CallPaymentIncomingTransferResult(
      session: session,
      installment: installment,
      ackEvent: ackEvent,
    );
  }

  void _validateRequest(CallPaymentIncomingTransferRequest request) {
    final payload = request.payload;
    if (payload.type != CallPaymentEventType.transfer) {
      throw ArgumentError('Incoming payment must be a transfer payload');
    }
    if (payload.payerPubkey != request.senderPubkey ||
        payload.payeePubkey != request.owner.value) {
      throw ArgumentError('Incoming payment participants do not match');
    }
    if (payload.token == null || payload.token!.isEmpty) {
      throw ArgumentError('Incoming payment transfer must include a token');
    }
    if (payload.amountSats <= 0 || payload.billingPeriodSeconds <= 0) {
      throw ArgumentError('Incoming payment transfer has invalid amounts');
    }
  }

  int _priceSatsPerMinute(CallPaymentEventPayload payload) {
    return (payload.amountSats * 60 / payload.billingPeriodSeconds).ceil();
  }
}
