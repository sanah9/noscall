import 'package:noscall/wallet/domain/cashu_models.dart';

import '../domain/call_payment_models.dart';
import 'call_payment_pricing_service.dart';

typedef CallPaymentPeerPolicyLoader =
    Future<CallPaymentPolicy?> Function(String peerPubkey);
typedef CallPaymentBalanceLoader = Future<Map<CashuMintUrl, int>> Function();
typedef CallPaymentContactChecker = bool Function(String peerPubkey);

enum CallPaymentStartDecisionKind {
  free,
  paid,
  noLocalMint,
  noCommonMint,
  insufficientBalance,
  unsupported,
}

final class CallPaymentStartDecision {
  const CallPaymentStartDecision._({
    required this.kind,
    required this.peerPubkey,
    required this.callType,
    required this.quote,
    required this.mintUrl,
    required this.balanceSats,
    required this.maxSpendSats,
    required this.message,
  });

  factory CallPaymentStartDecision.free({
    required String peerPubkey,
    required CallPaymentCallType callType,
    required CallPaymentPricingQuote quote,
  }) {
    return CallPaymentStartDecision._(
      kind: CallPaymentStartDecisionKind.free,
      peerPubkey: peerPubkey,
      callType: callType,
      quote: quote,
      mintUrl: null,
      balanceSats: 0,
      maxSpendSats: 0,
      message: null,
    );
  }

  factory CallPaymentStartDecision.paid({
    required String peerPubkey,
    required CallPaymentCallType callType,
    required CallPaymentPricingQuote quote,
    required CashuMintUrl mintUrl,
    required int balanceSats,
    required int maxSpendSats,
  }) {
    return CallPaymentStartDecision._(
      kind: CallPaymentStartDecisionKind.paid,
      peerPubkey: peerPubkey,
      callType: callType,
      quote: quote,
      mintUrl: mintUrl,
      balanceSats: balanceSats,
      maxSpendSats: maxSpendSats,
      message: null,
    );
  }

  factory CallPaymentStartDecision.noCommonMint({
    required String peerPubkey,
    required CallPaymentCallType callType,
    required CallPaymentPricingQuote quote,
  }) {
    return CallPaymentStartDecision._(
      kind: CallPaymentStartDecisionKind.noCommonMint,
      peerPubkey: peerPubkey,
      callType: callType,
      quote: quote,
      mintUrl: null,
      balanceSats: 0,
      maxSpendSats: 0,
      message: 'No shared Mint for this paid call',
    );
  }

  factory CallPaymentStartDecision.noLocalMint({
    required String peerPubkey,
    required CallPaymentCallType callType,
    required CallPaymentPricingQuote quote,
  }) {
    return CallPaymentStartDecision._(
      kind: CallPaymentStartDecisionKind.noLocalMint,
      peerPubkey: peerPubkey,
      callType: callType,
      quote: quote,
      mintUrl: null,
      balanceSats: 0,
      maxSpendSats: 0,
      message: 'No enabled sat Mint available for paid calls.',
    );
  }

  factory CallPaymentStartDecision.insufficientBalance({
    required String peerPubkey,
    required CallPaymentCallType callType,
    required CallPaymentPricingQuote quote,
    required CashuMintUrl? mintUrl,
    required int balanceSats,
  }) {
    return CallPaymentStartDecision._(
      kind: CallPaymentStartDecisionKind.insufficientBalance,
      peerPubkey: peerPubkey,
      callType: callType,
      quote: quote,
      mintUrl: mintUrl,
      balanceSats: balanceSats,
      maxSpendSats: 0,
      message: 'Not enough balance on this Mint',
    );
  }

  factory CallPaymentStartDecision.unsupported({
    required String peerPubkey,
    required CallPaymentCallType callType,
  }) {
    return CallPaymentStartDecision._(
      kind: CallPaymentStartDecisionKind.unsupported,
      peerPubkey: peerPubkey,
      callType: callType,
      quote: null,
      mintUrl: null,
      balanceSats: 0,
      maxSpendSats: 0,
      message: 'Peer does not support paid calls.',
    );
  }

  final CallPaymentStartDecisionKind kind;
  final String peerPubkey;
  final CallPaymentCallType callType;
  final CallPaymentPricingQuote? quote;
  final CashuMintUrl? mintUrl;
  final int balanceSats;
  final int maxSpendSats;
  final String? message;
}

final class CallPaymentStartGuard {
  CallPaymentStartGuard({
    required CallPaymentPeerPolicyLoader loadPeerPolicy,
    required CallPaymentBalanceLoader loadBalancesByMintSats,
    required CallPaymentContactChecker peerIsContact,
    CallPaymentPricingService pricingService =
        const CallPaymentPricingService(),
  }) : _loadPeerPolicy = loadPeerPolicy,
       _loadBalancesByMintSats = loadBalancesByMintSats,
       _peerIsContact = peerIsContact,
       _pricingService = pricingService;

  final CallPaymentPeerPolicyLoader _loadPeerPolicy;
  final CallPaymentBalanceLoader _loadBalancesByMintSats;
  final CallPaymentContactChecker _peerIsContact;
  final CallPaymentPricingService _pricingService;

  Future<CallPaymentStartDecision> evaluate({
    required String peerPubkey,
    required CallPaymentCallType callType,
  }) async {
    final policy = await _loadPeerPolicy(peerPubkey);
    if (policy == null) {
      return CallPaymentStartDecision.unsupported(
        peerPubkey: peerPubkey,
        callType: callType,
      );
    }

    final quote = _pricingService.quote(
      policy: policy,
      callType: callType,
      peerPubkey: peerPubkey,
      peerIsContact: _peerIsContact(peerPubkey),
    );
    if (quote.isFree) {
      return CallPaymentStartDecision.free(
        peerPubkey: peerPubkey,
        callType: callType,
        quote: quote,
      );
    }

    final balancesByMint = await _loadBalancesByMintSats();
    if (balancesByMint.isEmpty) {
      return CallPaymentStartDecision.noLocalMint(
        peerPubkey: peerPubkey,
        callType: callType,
        quote: quote,
      );
    }

    final commonMintUrls = policy.acceptedMintUrls
        .where((mintUrl) => balancesByMint.containsKey(mintUrl))
        .toList(growable: false);
    if (commonMintUrls.isEmpty) {
      return CallPaymentStartDecision.noCommonMint(
        peerPubkey: peerPubkey,
        callType: callType,
        quote: quote,
      );
    }

    CashuMintUrl? bestMintUrl;
    var bestBalance = 0;
    for (final mintUrl in commonMintUrls) {
      final balance = balancesByMint[mintUrl] ?? 0;
      if (balance >= quote.periodAmountSats) {
        final maxSpend = _defaultMaxSpend(balanceSats: balance, quote: quote);
        return CallPaymentStartDecision.paid(
          peerPubkey: peerPubkey,
          callType: callType,
          quote: quote,
          mintUrl: mintUrl,
          balanceSats: balance,
          maxSpendSats: maxSpend,
        );
      }
      if (bestMintUrl == null || balance > bestBalance) {
        bestMintUrl = mintUrl;
        bestBalance = balance;
      }
    }

    return CallPaymentStartDecision.insufficientBalance(
      peerPubkey: peerPubkey,
      callType: callType,
      quote: quote,
      mintUrl: bestMintUrl,
      balanceSats: bestBalance,
    );
  }

  int _defaultMaxSpend({
    required int balanceSats,
    required CallPaymentPricingQuote quote,
  }) {
    final capped = balanceSats < quote.defaultMaxSpendSats
        ? balanceSats
        : quote.defaultMaxSpendSats;
    final periods = capped ~/ quote.periodAmountSats;
    return periods * quote.periodAmountSats;
  }
}
