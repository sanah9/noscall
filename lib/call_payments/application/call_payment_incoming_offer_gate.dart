import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/utils/hash_util.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';

import '../domain/call_payment_models.dart';
import '../domain/call_payment_repositories.dart';
import 'call_payment_initial_payment_service.dart';
import 'call_payment_pricing_service.dart';
import 'call_payment_start_guard.dart';

typedef CallPaymentRequiredSender =
    Future<OKEvent> Function({
      required String receiverPubkey,
      required CallPaymentEventPayload payload,
    });

final class CallPaymentIncomingOfferDecision {
  const CallPaymentIncomingOfferDecision.allow()
    : allowed = true,
      rejectReason = null;

  const CallPaymentIncomingOfferDecision.reject(this.rejectReason)
    : allowed = false;

  final bool allowed;
  final String? rejectReason;
}

final class CallPaymentIncomingOfferGate {
  CallPaymentIncomingOfferGate({
    required CashuAccountId owner,
    required CallPaymentPolicyRepository policyRepository,
    required CallPaymentSessionRepository sessionRepository,
    required CallPaymentContactChecker peerIsContact,
    CallPaymentRequiredSender? sendPaymentRequired,
    CallPaymentPricingService pricingService =
        const CallPaymentPricingService(),
    CallPaymentClock? clock,
  }) : _owner = owner,
       _policyRepository = policyRepository,
       _sessionRepository = sessionRepository,
       _peerIsContact = peerIsContact,
       _sendPaymentRequired = sendPaymentRequired,
       _pricingService = pricingService,
       _clock = clock ?? DateTime.now;

  final CashuAccountId _owner;
  final CallPaymentPolicyRepository _policyRepository;
  final CallPaymentSessionRepository _sessionRepository;
  final CallPaymentContactChecker _peerIsContact;
  final CallPaymentRequiredSender? _sendPaymentRequired;
  final CallPaymentPricingService _pricingService;
  final CallPaymentClock _clock;

  Future<CallPaymentIncomingOfferDecision> evaluate({
    required String callId,
    required String peerPubkey,
    required CallPaymentCallType callType,
  }) async {
    final policy = await _policyRepository.find(_owner);
    if (policy == null) return const CallPaymentIncomingOfferDecision.allow();

    final quote = _pricingService.quote(
      policy: policy,
      callType: callType,
      peerPubkey: peerPubkey,
      peerIsContact: _peerIsContact(peerPubkey),
    );
    if (quote.isFree) return const CallPaymentIncomingOfferDecision.allow();

    final session = await _sessionRepository.find(_owner, callId);
    if (session == null) {
      await _sendRequiredIfConfigured(
        callId: callId,
        peerPubkey: peerPubkey,
        callType: callType,
        policy: policy,
        quote: quote,
      );
      return const CallPaymentIncomingOfferDecision.reject(
        'payment_required_upgrade',
      );
    }
    if (_isValidPaidIncomingSession(session, peerPubkey, callType, quote)) {
      return const CallPaymentIncomingOfferDecision.allow();
    }
    await _sendRequiredIfConfigured(
      callId: callId,
      peerPubkey: peerPubkey,
      callType: callType,
      policy: policy,
      quote: quote,
    );
    return const CallPaymentIncomingOfferDecision.reject(
      'payment_required_upgrade',
    );
  }

  Future<void> _sendRequiredIfConfigured({
    required String callId,
    required String peerPubkey,
    required CallPaymentCallType callType,
    required CallPaymentPolicy policy,
    required CallPaymentPricingQuote quote,
  }) async {
    final sender = _sendPaymentRequired;
    if (sender == null || policy.acceptedMintUrls.isEmpty) return;
    final now = _clock();
    final tokenHash = HashUtil.sha256String(
      'payment_required:$callId:${_owner.value}:$peerPubkey:${quote.periodAmountSats}',
    );
    final payload = CallPaymentEventPayload(
      type: CallPaymentEventType.required,
      callId: callId,
      paymentSessionId: '$callId:required',
      sequence: 1,
      purpose: CallPaymentPurpose.initial,
      callType: callType,
      payerPubkey: peerPubkey,
      payeePubkey: _owner.value,
      mintUrl: policy.acceptedMintUrls.first,
      amountSats: quote.periodAmountSats,
      billingPeriodSeconds: quote.billingPeriodSeconds,
      coversFromSecond: 0,
      coversToSecond: quote.billingPeriodSeconds,
      tokenHash: tokenHash,
      createdAt: now,
      expiresAt: now.add(Duration(seconds: quote.billingPeriodSeconds)),
    );
    try {
      await sender(receiverPubkey: peerPubkey, payload: payload);
    } catch (_) {
      // The offer remains rejected even when the advisory event cannot be sent.
    }
  }

  bool _isValidPaidIncomingSession(
    CallPaymentSession session,
    String peerPubkey,
    CallPaymentCallType callType,
    CallPaymentPricingQuote quote,
  ) {
    return session.owner == _owner &&
        session.peerPubkey == peerPubkey &&
        session.direction == CallPaymentCallDirection.incoming &&
        session.role == CallPaymentRole.payee &&
        session.callType == callType &&
        session.status == CallPaymentSessionStatus.ringing &&
        session.chargedSats >= quote.periodAmountSats;
  }
}
