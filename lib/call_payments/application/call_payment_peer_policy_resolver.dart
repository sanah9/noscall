import 'dart:async';

import 'package:noscall/wallet/domain/cashu_account_id.dart';

import '../domain/call_payment_models.dart';
import '../domain/call_payment_repositories.dart';

typedef CallPaymentPeerPolicyQuery =
    Future<CallPaymentPolicy?> Function(String peerPubkey);
typedef CallPaymentPeerPolicyClock = DateTime Function();

final class CallPaymentPeerPolicyResolver {
  CallPaymentPeerPolicyResolver({
    required CallPaymentPolicyRepository policyRepository,
    CallPaymentPeerPolicyQuery? queryPeerPolicy,
    Duration cacheTtl = const Duration(minutes: 10),
    Duration queryTimeout = const Duration(seconds: 10),
    CallPaymentPeerPolicyClock? clock,
  }) : _policyRepository = policyRepository,
       _queryPeerPolicy = queryPeerPolicy,
       _cacheTtl = cacheTtl,
       _queryTimeout = queryTimeout,
       _clock = clock ?? DateTime.now;

  final CallPaymentPolicyRepository _policyRepository;
  final CallPaymentPeerPolicyQuery? _queryPeerPolicy;
  final Duration _cacheTtl;
  final Duration _queryTimeout;
  final CallPaymentPeerPolicyClock _clock;

  Future<CallPaymentPolicy?> resolve(String peerPubkey) async {
    final peer = CashuAccountId.fromNostrPubkey(peerPubkey);
    final cached = await _policyRepository.find(peer);
    final now = _clock();
    if (cached != null && !_isExpired(cached, now)) return cached;

    final queryPeerPolicy = _queryPeerPolicy;
    if (queryPeerPolicy == null) return null;

    try {
      final queried = await queryPeerPolicy(peerPubkey).timeout(_queryTimeout);
      if (queried == null || queried.owner != peer) return null;
      final refreshed = queried.copyWith(updatedAt: now);
      await _policyRepository.save(refreshed);
      return refreshed;
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  bool _isExpired(CallPaymentPolicy policy, DateTime now) {
    return now.difference(policy.updatedAt) > _cacheTtl;
  }
}
