import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/application/mint_registry_service.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_engine.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';
import 'package:noscall/wallet/domain/wallet_configuration.dart';
import 'package:noscall/wallet/domain/wallet_errors.dart';

void main() {
  late _FakeMintInspector inspector;
  late _MemoryMintRepository repository;
  late DateTime now;
  late MintRegistryService service;

  setUp(() {
    inspector = _FakeMintInspector();
    repository = _MemoryMintRepository();
    now = DateTime.utc(2026, 6, 21);
    service = MintRegistryService(
      inspector: inspector,
      repository: repository,
      clock: () => now,
    );
  });

  test(
    'validates before confirmation and then upserts normalized URL',
    () async {
      final owner = _account('a');
      final url = CashuMintUrl.parse('https://mint.example.com');
      inspector.snapshots[url] = _supportedSnapshot(url);

      final preview = await service.validateManual(
        owner,
        '  https://MINT.example.com/  ',
      );

      expect(await repository.list(owner), isEmpty);
      final saved = await service.confirm(preview);
      expect(saved.url, url);
      expect(saved.enabled, isTrue);
      expect(saved.units, ['sat']);
      expect((await repository.list(owner)), hasLength(1));

      await service.confirm(preview);
      expect((await repository.list(owner)), hasLength(1));
    },
  );

  test('rejects a Mint without required recovery capability', () async {
    final owner = _account('b');
    final url = CashuMintUrl.parse('https://mint.example.com');
    inspector.snapshots[url] = _supportedSnapshot(
      url,
      nuts: _requiredNuts..remove(CashuNut.nut09),
    );

    await expectLater(
      service.validateManual(owner, url.toString()),
      throwsA(
        isA<UnsupportedMintException>().having(
          (error) => error.missingNutNumbers,
          'missing NUTs',
          {9},
        ),
      ),
    );
    expect(await repository.list(owner), isEmpty);
  });

  test(
    'refresh failure preserves snapshot and records safe error code',
    () async {
      final owner = _account('c');
      final url = CashuMintUrl.parse('https://mint.example.com');
      inspector.snapshots[url] = _supportedSnapshot(url);
      await service.confirm(
        await service.validateManual(owner, url.toString()),
      );
      inspector.errors[url] = const CashuProtocolException(
        'mint_unreachable',
        'unreachable',
      );

      await expectLater(
        service.refresh(owner, url),
        throwsA(isA<CashuProtocolException>()),
      );

      final stored = await repository.find(owner, url);
      expect(stored?.enabled, isTrue);
      expect(stored?.supportedNuts, _requiredNuts);
      expect(stored?.lastError, 'mint_unreachable');
    },
  );

  test('revalidates a disabled Mint before enabling it', () async {
    final owner = _account('d');
    final url = CashuMintUrl.parse('https://mint.example.com');
    inspector.snapshots[url] = _supportedSnapshot(url);
    await service.confirm(await service.validateManual(owner, url.toString()));
    await service.setEnabled(owner, url, false);
    final callsBeforeEnable = inspector.calls;

    final enabled = await service.setEnabled(owner, url, true);

    expect(enabled.enabled, isTrue);
    expect(inspector.calls, callsBeforeEnable + 1);
  });

  test('removes only an existing account-scoped Mint', () async {
    final owner = _account('e');
    final otherOwner = _account('f');
    final url = CashuMintUrl.parse('https://mint.example.com');
    inspector.snapshots[url] = _supportedSnapshot(url);
    await service.confirm(await service.validateManual(owner, url.toString()));
    await service.confirm(
      await service.validateManual(otherOwner, url.toString()),
    );

    await service.remove(owner, url);

    expect(await repository.find(owner, url), isNull);
    expect(await repository.find(otherOwner, url), isNotNull);
    await expectLater(service.remove(owner, url), throwsStateError);
  });
}

Set<CashuNut> get _requiredNuts => {
  CashuNut.nut00,
  CashuNut.nut01,
  CashuNut.nut02,
  CashuNut.nut03,
  CashuNut.nut06,
  CashuNut.nut07,
  CashuNut.nut09,
};

CashuMintSnapshot _supportedSnapshot(CashuMintUrl url, {Set<CashuNut>? nuts}) {
  return CashuMintSnapshot(
    url: url,
    name: 'Test Mint',
    description: 'Test description',
    supportedNuts: nuts ?? _requiredNuts,
    supportsSat: true,
    supportsBolt11Mint: false,
    supportsBolt11Melt: false,
  );
}

CashuAccountId _account(String character) =>
    CashuAccountId.fromNostrPubkey(character * 64);

final class _FakeMintInspector implements CashuMintInspector {
  final Map<CashuMintUrl, CashuMintSnapshot> snapshots = {};
  final Map<CashuMintUrl, Object> errors = {};
  int calls = 0;

  @override
  Future<CashuMintSnapshot> inspectMint(CashuMintUrl mintUrl) async {
    calls++;
    final error = errors[mintUrl];
    if (error != null) throw error;
    final snapshot = snapshots[mintUrl];
    if (snapshot == null) throw StateError('Missing fake Mint snapshot');
    return snapshot;
  }
}

final class _MemoryMintRepository implements MintConfigurationRepository {
  final Map<String, MintConfiguration> values = {};

  String _key(CashuAccountId owner, CashuMintUrl url) =>
      '${owner.value}|${url.toString()}';

  @override
  Future<void> delete(CashuAccountId owner, CashuMintUrl url) async {
    values.remove(_key(owner, url));
  }

  @override
  Future<MintConfiguration?> find(
    CashuAccountId owner,
    CashuMintUrl url,
  ) async => values[_key(owner, url)];

  @override
  Future<List<MintConfiguration>> list(CashuAccountId owner) async => values
      .values
      .where((configuration) => configuration.owner == owner)
      .toList(growable: false);

  @override
  Future<void> save(MintConfiguration configuration) async {
    values[_key(configuration.owner, configuration.url)] = configuration;
  }
}
