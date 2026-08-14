import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call_payments/application/call_payment_policy_service.dart';
import 'package:noscall/call_payments/application/call_payment_pricing_service.dart';
import 'package:noscall/call_payments/domain/call_payment_errors.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/domain/call_payment_repositories.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';
import 'package:noscall/wallet/domain/wallet_configuration.dart';

void main() {
  test('creates default policy from enabled sat Mints', () async {
    final owner = CashuAccountId.fromNostrPubkey('a' * 64);
    final repository = _PolicyRepository();
    final mintRepository = _MintRepository([
      _mint(owner: owner, url: 'https://mint-a.example', enabled: true),
      _mint(owner: owner, url: 'https://mint-b.example', enabled: false),
      _mint(
        owner: owner,
        url: 'https://mint-c.example',
        enabled: true,
        units: const ['usd'],
      ),
    ]);
    final service = CallPaymentPolicyService(
      policyRepository: repository,
      mintRepository: mintRepository,
      clock: () => DateTime.utc(2026, 8, 14),
    );

    final policy = await service.ensure(owner);

    expect(policy.enabled, isFalse);
    expect(policy.freePolicy, CallPaymentFreePolicy.contactsFree);
    expect(
      policy.audioPriceSatsPerMinute,
      CallPaymentPricingService.defaultAudioPriceSatsPerMinute,
    );
    expect(
      policy.videoPriceSatsPerMinute,
      CallPaymentPricingService.defaultVideoPriceSatsPerMinute,
    );
    expect(policy.acceptedMintUrls.map((url) => url.toString()), [
      'https://mint-a.example',
    ]);
    expect(await repository.find(owner), isNotNull);
  });

  test(
    'enables policy by filling empty accepted Mints from enabled sat Mints',
    () async {
      final owner = CashuAccountId.fromNostrPubkey('b' * 64);
      final repository = _PolicyRepository();
      final mintRepository = _MintRepository([
        _mint(owner: owner, url: 'https://mint.example', enabled: true),
      ]);
      final service = CallPaymentPolicyService(
        policyRepository: repository,
        mintRepository: mintRepository,
        clock: () => DateTime.utc(2026, 8, 14),
      );

      final policy = await service.setEnabled(owner, true);

      expect(policy.enabled, isTrue);
      expect(policy.acceptedMintUrls.single.toString(), 'https://mint.example');
    },
  );

  test('does not enable paid calls without an accepted Mint', () async {
    final owner = CashuAccountId.fromNostrPubkey('c' * 64);
    final service = CallPaymentPolicyService(
      policyRepository: _PolicyRepository(),
      mintRepository: _MintRepository(const []),
    );

    await expectLater(
      service.setEnabled(owner, true),
      throwsA(isA<NoAcceptedCallPaymentMintException>()),
    );
  });

  test('rejects disabled or non-sat accepted Mints', () async {
    final owner = CashuAccountId.fromNostrPubkey('d' * 64);
    final disabledUrl = CashuMintUrl.parse('https://disabled.example');
    final nonSatUrl = CashuMintUrl.parse('https://nonsat.example');
    final mintRepository = _MintRepository([
      _mint(owner: owner, url: disabledUrl.toString(), enabled: false),
      _mint(
        owner: owner,
        url: nonSatUrl.toString(),
        enabled: true,
        units: const ['usd'],
      ),
    ]);
    final service = CallPaymentPolicyService(
      policyRepository: _PolicyRepository(),
      mintRepository: mintRepository,
    );

    await expectLater(
      service.save(_policy(owner, acceptedMintUrls: [disabledUrl])),
      throwsA(
        isA<UnsupportedCallPaymentMintException>().having(
          (error) => error.mintUrl,
          'mintUrl',
          disabledUrl,
        ),
      ),
    );
    await expectLater(
      service.save(_policy(owner, acceptedMintUrls: [nonSatUrl])),
      throwsA(isA<UnsupportedCallPaymentMintException>()),
    );
  });

  test('updates saved policy timestamp with service clock', () async {
    final owner = CashuAccountId.fromNostrPubkey('e' * 64);
    final url = CashuMintUrl.parse('https://mint.example');
    final repository = _PolicyRepository();
    final service = CallPaymentPolicyService(
      policyRepository: repository,
      mintRepository: _MintRepository([
        _mint(owner: owner, url: url.toString(), enabled: true),
      ]),
      clock: () => DateTime.utc(2026, 8, 14, 12),
    );

    final saved = await service.save(_policy(owner, acceptedMintUrls: [url]));

    expect(saved.updatedAt, DateTime.utc(2026, 8, 14, 12));
    expect((await repository.find(owner))?.updatedAt, saved.updatedAt);
  });
}

CallPaymentPolicy _policy(
  CashuAccountId owner, {
  required Iterable<CashuMintUrl> acceptedMintUrls,
}) {
  final now = DateTime.utc(2026, 8, 14);
  return CallPaymentPolicy(
    owner: owner,
    enabled: true,
    freePolicy: CallPaymentFreePolicy.contactsFree,
    freePubkeys: const [],
    audioPriceSatsPerMinute: 10,
    videoPriceSatsPerMinute: 30,
    billingPeriodSeconds: 60,
    gracePeriodSeconds: 10,
    acceptedMintUrls: acceptedMintUrls,
    createdAt: now,
    updatedAt: now,
  );
}

MintConfiguration _mint({
  required CashuAccountId owner,
  required String url,
  required bool enabled,
  Iterable<String> units = const ['sat'],
}) {
  return MintConfiguration(
    owner: owner,
    url: CashuMintUrl.parse(url),
    enabled: enabled,
    source: MintConfigurationSource.manual,
    supportedNuts: const {CashuNut.nut00},
    units: units,
    lastSyncAt: DateTime.utc(2026, 8, 14),
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

final class _MintRepository implements MintConfigurationRepository {
  _MintRepository(Iterable<MintConfiguration> mints) {
    for (final mint in mints) {
      values[_key(mint.owner, mint.url)] = mint;
    }
  }

  final Map<String, MintConfiguration> values = {};

  String _key(CashuAccountId owner, CashuMintUrl url) {
    return '${owner.value}|${url.toString()}';
  }

  @override
  Future<void> delete(CashuAccountId owner, CashuMintUrl url) async {
    values.remove(_key(owner, url));
  }

  @override
  Future<MintConfiguration?> find(
    CashuAccountId owner,
    CashuMintUrl url,
  ) async {
    return values[_key(owner, url)];
  }

  @override
  Future<List<MintConfiguration>> list(CashuAccountId owner) async {
    return values.values
        .where((configuration) => configuration.owner == owner)
        .toList(growable: false);
  }

  @override
  Future<void> save(MintConfiguration configuration) async {
    values[_key(configuration.owner, configuration.url)] = configuration;
  }
}
