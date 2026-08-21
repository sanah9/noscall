import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call_payments/application/call_payment_pricing_service.dart';
import 'package:noscall/call_payments/application/call_payment_start_guard.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  test('allows free calls when the peer policy is disabled', () async {
    final mint = CashuMintUrl.parse('https://mint.example');
    final guard = _guard(policy: _policy(enabled: false, mints: [mint]));

    final decision = await guard.evaluate(
      peerPubkey: _peerPubkey,
      callType: CallPaymentCallType.audio,
    );

    expect(decision.kind, CallPaymentStartDecisionKind.free);
    expect(decision.quote?.freeReason, 'policy_disabled');
  });

  test(
    'returns a paid confirmation decision with shared Mint and balance',
    () async {
      final mint = CashuMintUrl.parse('https://mint.example');
      final guard = _guard(
        policy: _policy(mints: [mint]),
        balances: {mint: 250},
      );

      final decision = await guard.evaluate(
        peerPubkey: _peerPubkey,
        callType: CallPaymentCallType.audio,
      );

      expect(decision.kind, CallPaymentStartDecisionKind.paid);
      expect(decision.mintUrl, mint);
      expect(decision.balanceSats, 250);
      expect(decision.quote?.periodAmountSats, 10);
      expect(decision.maxSpendSats, 100);
    },
  );

  test('caps default max spend by selected Mint balance', () async {
    final mint = CashuMintUrl.parse('https://mint.example');
    final guard = _guard(
      policy: _policy(mints: [mint]),
      balances: {mint: 35},
    );

    final decision = await guard.evaluate(
      peerPubkey: _peerPubkey,
      callType: CallPaymentCallType.audio,
    );

    expect(decision.kind, CallPaymentStartDecisionKind.paid);
    expect(decision.maxSpendSats, 30);
  });

  test('fails without a shared Mint and does not suggest one', () async {
    final payeeMint = CashuMintUrl.parse('https://payee.example');
    final payerMint = CashuMintUrl.parse('https://payer.example');
    final guard = _guard(
      policy: _policy(mints: [payeeMint]),
      balances: {payerMint: 100},
    );

    final decision = await guard.evaluate(
      peerPubkey: _peerPubkey,
      callType: CallPaymentCallType.audio,
    );

    expect(decision.kind, CallPaymentStartDecisionKind.noCommonMint);
    expect(decision.mintUrl, isNull);
    expect(decision.message, 'No shared Mint for this paid call');
  });

  test(
    'fails with a local Mint setup prompt when payer has no Mints',
    () async {
      final payeeMint = CashuMintUrl.parse('https://payee.example');
      final guard = _guard(policy: _policy(mints: [payeeMint]));

      final decision = await guard.evaluate(
        peerPubkey: _peerPubkey,
        callType: CallPaymentCallType.audio,
      );

      expect(decision.kind, CallPaymentStartDecisionKind.noLocalMint);
      expect(decision.mintUrl, isNull);
      expect(decision.message, 'No enabled sat Mint available for paid calls.');
    },
  );

  test('fails when shared Mint cannot cover the first period', () async {
    final mint = CashuMintUrl.parse('https://mint.example');
    final guard = _guard(
      policy: _policy(mints: [mint]),
      balances: {mint: 9},
    );

    final decision = await guard.evaluate(
      peerPubkey: _peerPubkey,
      callType: CallPaymentCallType.audio,
    );

    expect(decision.kind, CallPaymentStartDecisionKind.insufficientBalance);
    expect(decision.mintUrl, mint);
    expect(decision.balanceSats, 9);
    expect(decision.message, 'Not enough balance on this Mint');
  });

  test('fails closed when peer pricing cannot be confirmed', () async {
    final guard = _guard(policy: null);

    final decision = await guard.evaluate(
      peerPubkey: _peerPubkey,
      callType: CallPaymentCallType.audio,
    );

    expect(decision.kind, CallPaymentStartDecisionKind.unsupported);
    expect(decision.message, 'Peer does not support paid calls.');
  });

  test('honors contacts-free policy before checking balances', () async {
    final mint = CashuMintUrl.parse('https://mint.example');
    final guard = _guard(
      policy: _policy(mints: [mint]),
      contacts: {_peerPubkey},
    );

    final decision = await guard.evaluate(
      peerPubkey: _peerPubkey,
      callType: CallPaymentCallType.audio,
    );

    expect(decision.kind, CallPaymentStartDecisionKind.free);
    expect(decision.quote?.freeReason, 'contact_free');
  });
}

const _peerPubkey =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

CallPaymentStartGuard _guard({
  required CallPaymentPolicy? policy,
  Map<CashuMintUrl, int> balances = const {},
  Set<String> contacts = const {},
}) {
  return CallPaymentStartGuard(
    loadPeerPolicy: (_) async => policy,
    loadBalancesByMintSats: () async => balances,
    peerIsContact: contacts.contains,
  );
}

CallPaymentPolicy _policy({
  bool enabled = true,
  Iterable<CashuMintUrl> mints = const [],
}) {
  final now = DateTime.utc(2026, 8, 14);
  return CallPaymentPolicy(
    owner: CashuAccountId.fromNostrPubkey(_peerPubkey),
    enabled: enabled,
    freePolicy: CallPaymentFreePolicy.contactsFree,
    freePubkeys: const [],
    audioPriceSatsPerMinute:
        CallPaymentPricingService.defaultAudioPriceSatsPerMinute,
    videoPriceSatsPerMinute:
        CallPaymentPricingService.defaultVideoPriceSatsPerMinute,
    billingPeriodSeconds: CallPaymentPricingService.defaultBillingPeriodSeconds,
    gracePeriodSeconds: CallPaymentPricingService.defaultGracePeriodSeconds,
    acceptedMintUrls: mints,
    createdAt: now,
    updatedAt: now,
  );
}
