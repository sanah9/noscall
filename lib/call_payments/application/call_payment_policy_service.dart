import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';
import 'package:noscall/wallet/domain/wallet_configuration.dart';

import '../domain/call_payment_errors.dart';
import '../domain/call_payment_models.dart';
import '../domain/call_payment_repositories.dart';
import 'call_payment_pricing_service.dart';

typedef CallPaymentClock = DateTime Function();

final class CallPaymentPolicyService {
  CallPaymentPolicyService({
    required CallPaymentPolicyRepository policyRepository,
    required MintConfigurationRepository mintRepository,
    CallPaymentClock? clock,
  }) : _policyRepository = policyRepository,
       _mintRepository = mintRepository,
       _clock = clock ?? DateTime.now;

  final CallPaymentPolicyRepository _policyRepository;
  final MintConfigurationRepository _mintRepository;
  final CallPaymentClock _clock;

  Future<CallPaymentPolicy> ensure(CashuAccountId owner) async {
    final existing = await _policyRepository.find(owner);
    if (existing != null) return existing;

    final now = _clock();
    final policy = CallPaymentPolicy(
      owner: owner,
      enabled: false,
      freePolicy: CallPaymentFreePolicy.contactsFree,
      freePubkeys: const [],
      audioPriceSatsPerMinute:
          CallPaymentPricingService.defaultAudioPriceSatsPerMinute,
      videoPriceSatsPerMinute:
          CallPaymentPricingService.defaultVideoPriceSatsPerMinute,
      billingPeriodSeconds:
          CallPaymentPricingService.defaultBillingPeriodSeconds,
      gracePeriodSeconds: CallPaymentPricingService.defaultGracePeriodSeconds,
      acceptedMintUrls: await _enabledSatMintUrls(owner),
      createdAt: now,
      updatedAt: now,
    );
    await _policyRepository.save(policy);
    return policy;
  }

  Future<CallPaymentPolicy> save(CallPaymentPolicy policy) async {
    await _validate(policy);
    final updated = policy.copyWith(updatedAt: _clock());
    await _policyRepository.save(updated);
    return updated;
  }

  Future<CallPaymentPolicy> setEnabled(
    CashuAccountId owner,
    bool enabled,
  ) async {
    final current = await ensure(owner);
    final acceptedMintUrls = current.acceptedMintUrls.isEmpty
        ? await _enabledSatMintUrls(owner)
        : current.acceptedMintUrls;
    return save(
      current.copyWith(enabled: enabled, acceptedMintUrls: acceptedMintUrls),
    );
  }

  Future<List<CashuMintUrl>> loadAvailableMintUrls(CashuAccountId owner) {
    return _enabledSatMintUrls(owner);
  }

  Future<void> _validate(CallPaymentPolicy policy) async {
    if (policy.audioPriceSatsPerMinute < 0 ||
        policy.videoPriceSatsPerMinute < 0) {
      throw const InvalidCallPaymentPriceException();
    }
    if (policy.billingPeriodSeconds !=
            CallPaymentPricingService.defaultBillingPeriodSeconds ||
        policy.gracePeriodSeconds !=
            CallPaymentPricingService.defaultGracePeriodSeconds) {
      throw const InvalidCallPaymentTimingException();
    }
    if (!policy.enabled) return;
    if (policy.acceptedMintUrls.isEmpty) {
      throw const NoAcceptedCallPaymentMintException();
    }

    final enabledMints = await _enabledSatMints(policy.owner);
    final enabledUrls = enabledMints.map((mint) => mint.url).toSet();
    for (final mintUrl in policy.acceptedMintUrls) {
      if (!enabledUrls.contains(mintUrl)) {
        throw UnsupportedCallPaymentMintException(mintUrl);
      }
    }
  }

  Future<List<CashuMintUrl>> _enabledSatMintUrls(CashuAccountId owner) async {
    return (await _enabledSatMints(
      owner,
    )).map((mint) => mint.url).toList(growable: false);
  }

  Future<List<MintConfiguration>> _enabledSatMints(CashuAccountId owner) async {
    final mints = await _mintRepository.list(owner);
    return mints
        .where((mint) => mint.enabled && mint.units.contains('sat'))
        .toList(growable: false);
  }
}
