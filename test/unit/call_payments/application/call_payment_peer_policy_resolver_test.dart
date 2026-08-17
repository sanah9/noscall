import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call_payments/application/call_payment_peer_policy_resolver.dart';
import 'package:noscall/call_payments/application/call_payment_pricing_service.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/domain/call_payment_repositories.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  test('returns fresh cached peer policy without querying', () async {
    final repository = _PolicyRepository()
      ..policies[_peer] = _policy(updatedAt: DateTime.utc(2026, 8, 14, 9, 55));
    var queryCalls = 0;
    final resolver = _resolver(
      repository: repository,
      queryPeerPolicy: (_) async {
        queryCalls++;
        return null;
      },
    );

    final policy = await resolver.resolve(_peer.value);

    expect(policy?.owner, _peer);
    expect(queryCalls, 0);
  });

  test('queries and caches expired peer policy', () async {
    final repository = _PolicyRepository()
      ..policies[_peer] = _policy(updatedAt: DateTime.utc(2026, 8, 14, 9, 40));
    final queried = _policy(
      audioPriceSatsPerMinute: 21,
      updatedAt: DateTime.utc(2026, 8, 14, 9, 41),
    );
    final resolver = _resolver(
      repository: repository,
      queryPeerPolicy: (_) async => queried,
    );

    final policy = await resolver.resolve(_peer.value);

    expect(policy?.audioPriceSatsPerMinute, 21);
    expect(policy?.updatedAt, DateTime.utc(2026, 8, 14, 10));
    expect(repository.policies[_peer]?.audioPriceSatsPerMinute, 21);
  });

  test('fails closed when expired policy query times out', () async {
    final repository = _PolicyRepository()
      ..policies[_peer] = _policy(updatedAt: DateTime.utc(2026, 8, 14, 9, 40));
    final resolver = _resolver(
      repository: repository,
      queryTimeout: const Duration(milliseconds: 1),
      queryPeerPolicy: (_) => Completer<CallPaymentPolicy?>().future,
    );

    final policy = await resolver.resolve(_peer.value);

    expect(policy, isNull);
  });

  test('rejects queried policy for a different peer', () async {
    final repository = _PolicyRepository();
    final resolver = _resolver(
      repository: repository,
      queryPeerPolicy: (_) async => _policy(owner: _otherPeer),
    );

    final policy = await resolver.resolve(_peer.value);

    expect(policy, isNull);
    expect(repository.policies, isEmpty);
  });
}

final _peer = CashuAccountId.fromNostrPubkey('a' * 64);
final _otherPeer = CashuAccountId.fromNostrPubkey('b' * 64);
final _mintUrl = CashuMintUrl.parse('https://mint.example');

CallPaymentPeerPolicyResolver _resolver({
  required _PolicyRepository repository,
  CallPaymentPeerPolicyQuery? queryPeerPolicy,
  Duration queryTimeout = const Duration(seconds: 10),
}) {
  return CallPaymentPeerPolicyResolver(
    policyRepository: repository,
    queryPeerPolicy: queryPeerPolicy,
    queryTimeout: queryTimeout,
    clock: () => DateTime.utc(2026, 8, 14, 10),
  );
}

CallPaymentPolicy _policy({
  CashuAccountId? owner,
  int audioPriceSatsPerMinute =
      CallPaymentPricingService.defaultAudioPriceSatsPerMinute,
  DateTime? updatedAt,
}) {
  final createdAt = DateTime.utc(2026, 8, 14, 9);
  return CallPaymentPolicy(
    owner: owner ?? _peer,
    enabled: true,
    freePolicy: CallPaymentFreePolicy.contactsFree,
    freePubkeys: const [],
    audioPriceSatsPerMinute: audioPriceSatsPerMinute,
    videoPriceSatsPerMinute:
        CallPaymentPricingService.defaultVideoPriceSatsPerMinute,
    billingPeriodSeconds: CallPaymentPricingService.defaultBillingPeriodSeconds,
    gracePeriodSeconds: CallPaymentPricingService.defaultGracePeriodSeconds,
    acceptedMintUrls: [_mintUrl],
    createdAt: createdAt,
    updatedAt: updatedAt ?? createdAt,
  );
}

final class _PolicyRepository implements CallPaymentPolicyRepository {
  final Map<CashuAccountId, CallPaymentPolicy> policies = {};

  @override
  Future<CallPaymentPolicy?> find(CashuAccountId owner) async {
    return policies[owner];
  }

  @override
  Future<void> save(CallPaymentPolicy policy) async {
    policies[policy.owner] = policy;
  }
}
