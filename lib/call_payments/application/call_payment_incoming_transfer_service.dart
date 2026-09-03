import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/utils/hash_util.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

import '../domain/call_payment_models.dart';
import '../domain/call_payment_repositories.dart';
import 'call_payment_initial_payment_service.dart';
import 'call_payment_pricing_service.dart';
import 'call_payment_start_guard.dart';

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
    CallPaymentPolicyRepository? policyRepository,
    CallPaymentContactChecker? peerIsContact,
    CallPaymentPricingService pricingService =
        const CallPaymentPricingService(),
    CallPaymentClock? clock,
  }) : _sessionRepository = sessionRepository,
       _installmentRepository = installmentRepository,
       _tokenReceiver = tokenReceiver,
       _gateway = gateway,
       _policyRepository = policyRepository,
       _peerIsContact = peerIsContact,
       _pricingService = pricingService,
       _clock = clock ?? DateTime.now;

  final CallPaymentSessionRepository _sessionRepository;
  final CallPaymentInstallmentRepository _installmentRepository;
  final CallPaymentTokenReceiver _tokenReceiver;
  final CallPaymentTransferGateway _gateway;
  final CallPaymentPolicyRepository? _policyRepository;
  final CallPaymentContactChecker? _peerIsContact;
  final CallPaymentPricingService _pricingService;
  final CallPaymentClock _clock;

  Future<CallPaymentIncomingTransferResult> receiveAndAck(
    CallPaymentIncomingTransferRequest request,
  ) async {
    _validateRequest(request);
    final payload = request.payload;
    final existingInstallment = await _installmentRepository.find(
      owner: request.owner,
      callId: payload.callId,
      sequence: payload.sequence,
      purpose: payload.purpose,
      direction: CallPaymentTransferDirection.received,
    );
    if (existingInstallment != null) {
      return _ackExistingTransfer(request, existingInstallment);
    }

    await _validateAgainstPolicy(request);
    final existingSession = await _validateNewTransferSession(request);
    final token = payload.token!;
    final received = await _tokenReceiver.receive(token);
    if (received.amount.value != payload.amountSats) {
      throw ArgumentError('Incoming payment token amount does not match');
    }
    final now = _clock();
    final session = await _upsertSession(
      request: request,
      payload: payload,
      existing: existingSession,
      now: now,
    );

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

    final ackEvent = await _sendAck(request);
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
    if (HashUtil.sha256String(payload.token!) != payload.tokenHash) {
      throw ArgumentError('Incoming payment token hash does not match');
    }
    if (payload.amountSats <= 0 || payload.billingPeriodSeconds <= 0) {
      throw ArgumentError('Incoming payment transfer has invalid amounts');
    }
    if (payload.purpose != CallPaymentPurpose.initial &&
        payload.purpose != CallPaymentPurpose.topUp) {
      throw ArgumentError('Incoming payment transfer has invalid purpose');
    }
    if (payload.coversToSecond - payload.coversFromSecond !=
        payload.billingPeriodSeconds) {
      throw ArgumentError(
        'Incoming payment coverage must match billing period',
      );
    }
    if (payload.callType != request.callType) {
      throw ArgumentError('Incoming payment call type does not match');
    }
    if (payload.purpose == CallPaymentPurpose.initial &&
        (payload.sequence != 1 ||
            payload.coversFromSecond != 0 ||
            payload.coversToSecond != payload.billingPeriodSeconds)) {
      throw ArgumentError('Initial payment transfer has invalid coverage');
    }
  }

  Future<void> _validateAgainstPolicy(
    CallPaymentIncomingTransferRequest request,
  ) async {
    final policyRepository = _policyRepository;
    if (policyRepository == null) return;

    final payload = request.payload;
    final policy = await policyRepository.find(request.owner);
    if (policy == null) return;

    final quote = _pricingService.quote(
      policy: policy,
      callType: request.callType,
      peerPubkey: payload.payerPubkey,
      peerIsContact: _peerIsContact?.call(payload.payerPubkey) ?? false,
    );
    if (quote.isFree) return;

    if (!policy.acceptedMintUrls.contains(payload.mintUrl)) {
      throw ArgumentError('payment_mint_not_accepted');
    }
    if (payload.billingPeriodSeconds != quote.billingPeriodSeconds) {
      throw ArgumentError('payment_billing_period_mismatch');
    }
    if (payload.amountSats < quote.periodAmountSats) {
      throw ArgumentError('payment_insufficient');
    }
  }

  int _priceSatsPerMinute(CallPaymentEventPayload payload) {
    return (payload.amountSats * 60 / payload.billingPeriodSeconds).ceil();
  }

  Future<CallPaymentSession?> _validateNewTransferSession(
    CallPaymentIncomingTransferRequest request,
  ) async {
    final payload = request.payload;
    final existing = await _sessionRepository.find(
      request.owner,
      payload.callId,
    );
    if (payload.purpose == CallPaymentPurpose.initial) {
      if (existing != null) {
        _validateExistingInitialSession(existing, request);
      }
      return existing;
    }
    if (existing == null) {
      throw StateError('Top-up payment requires an existing paid call');
    }
    if (existing.status != CallPaymentSessionStatus.connected ||
        existing.direction != CallPaymentCallDirection.incoming ||
        existing.role != CallPaymentRole.payee ||
        existing.peerPubkey != payload.payerPubkey ||
        existing.callType != request.callType ||
        existing.mintUrl != payload.mintUrl) {
      throw StateError('Top-up payment does not match connected paid call');
    }
    final installments = await _installmentRepository.listForCall(
      owner: request.owner,
      callId: payload.callId,
    );
    _validateTopUpCoverage(payload, installments);
    return existing;
  }

  void _validateExistingInitialSession(
    CallPaymentSession existing,
    CallPaymentIncomingTransferRequest request,
  ) {
    final payload = request.payload;
    final activeStatus =
        existing.status == CallPaymentSessionStatus.ringing ||
        existing.status == CallPaymentSessionStatus.connected;
    if (!activeStatus ||
        existing.direction != CallPaymentCallDirection.incoming ||
        existing.role != CallPaymentRole.payee ||
        existing.peerPubkey != payload.payerPubkey ||
        existing.callType != request.callType ||
        existing.mintUrl != payload.mintUrl ||
        existing.billingPeriodSeconds != payload.billingPeriodSeconds) {
      throw StateError('Initial payment does not match existing paid call');
    }
  }

  void _validateTopUpCoverage(
    CallPaymentEventPayload payload,
    List<CallPaymentInstallment> installments,
  ) {
    final paidTransfers = installments
        .where(
          (installment) =>
              installment.direction == CallPaymentTransferDirection.received &&
              installment.purpose != CallPaymentPurpose.refund &&
              installment.status == CallPaymentInstallmentStatus.claimed,
        )
        .toList(growable: false);
    if (paidTransfers.isEmpty) {
      throw StateError('Top-up payment requires an existing paid period');
    }

    final expectedSequence =
        paidTransfers
            .map((installment) => installment.sequence)
            .reduce((a, b) => a > b ? a : b) +
        1;
    final expectedCoverageStart = paidTransfers
        .map((installment) => installment.coversToSecond)
        .reduce((a, b) => a > b ? a : b);
    final paymentSessionId = paidTransfers.first.paymentSessionId;
    if (payload.sequence != expectedSequence ||
        payload.coversFromSecond != expectedCoverageStart ||
        payload.paymentSessionId != paymentSessionId) {
      throw ArgumentError('Top-up payment coverage is not contiguous');
    }
  }

  Future<CallPaymentIncomingTransferResult> _ackExistingTransfer(
    CallPaymentIncomingTransferRequest request,
    CallPaymentInstallment installment,
  ) async {
    _validateExistingTransfer(installment, request.payload);
    final session = await _sessionRepository.find(
      request.owner,
      request.payload.callId,
    );
    if (session == null) {
      throw StateError('Payment session does not exist for received transfer');
    }
    var updatedInstallment = installment;
    final ackEvent = await _sendAck(request);
    if (!ackEvent.status) {
      updatedInstallment = installment.copyWith(
        updatedAt: _clock(),
        errorCode: 'payment_ack_send_failed',
      );
      await _installmentRepository.save(updatedInstallment);
    }
    return CallPaymentIncomingTransferResult(
      session: session,
      installment: updatedInstallment,
      ackEvent: ackEvent,
    );
  }

  void _validateExistingTransfer(
    CallPaymentInstallment installment,
    CallPaymentEventPayload payload,
  ) {
    if (installment.paymentSessionId != payload.paymentSessionId ||
        installment.amountSats != payload.amountSats ||
        installment.mintUrl != payload.mintUrl ||
        installment.tokenHash != payload.tokenHash ||
        installment.coversFromSecond != payload.coversFromSecond ||
        installment.coversToSecond != payload.coversToSecond) {
      throw ArgumentError('Duplicate payment transfer does not match');
    }
  }

  Future<OKEvent> _sendAck(CallPaymentIncomingTransferRequest request) {
    final payload = request.payload;
    final ackPayload = CallPaymentEventPayload(
      type: CallPaymentEventType.ack,
      callId: payload.callId,
      paymentSessionId: payload.paymentSessionId,
      sequence: payload.sequence,
      purpose: payload.purpose,
      callType: payload.callType,
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
    return _gateway.send(
      receiverPubkey: payload.payerPubkey,
      payload: ackPayload,
    );
  }

  Future<CallPaymentSession> _upsertSession({
    required CallPaymentIncomingTransferRequest request,
    required CallPaymentEventPayload payload,
    required CallPaymentSession? existing,
    required DateTime now,
  }) async {
    if (existing == null) {
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
      return session;
    }

    final session = existing.copyWith(
      status: existing.status == CallPaymentSessionStatus.connected
          ? CallPaymentSessionStatus.connected
          : CallPaymentSessionStatus.ringing,
      chargedSats: existing.chargedSats + payload.amountSats,
      updatedAt: now,
    );
    await _sessionRepository.save(session);
    return session;
  }
}
