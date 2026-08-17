import 'package:noscall/wallet/domain/cashu_account_id.dart';

import '../domain/call_payment_models.dart';
import '../domain/call_payment_repositories.dart';
import 'call_payment_pricing_service.dart';
import 'call_payment_start_guard.dart';

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
    CallPaymentPricingService pricingService =
        const CallPaymentPricingService(),
  }) : _owner = owner,
       _policyRepository = policyRepository,
       _sessionRepository = sessionRepository,
       _peerIsContact = peerIsContact,
       _pricingService = pricingService;

  final CashuAccountId _owner;
  final CallPaymentPolicyRepository _policyRepository;
  final CallPaymentSessionRepository _sessionRepository;
  final CallPaymentContactChecker _peerIsContact;
  final CallPaymentPricingService _pricingService;

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
      return const CallPaymentIncomingOfferDecision.reject(
        'payment_required_upgrade',
      );
    }
    if (_isValidPaidIncomingSession(session, peerPubkey, callType, quote)) {
      return const CallPaymentIncomingOfferDecision.allow();
    }
    return const CallPaymentIncomingOfferDecision.reject(
      'payment_required_upgrade',
    );
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
