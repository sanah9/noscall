import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/application/mint_management_controller.dart';
import 'package:noscall/wallet/application/mint_registry_service.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_engine.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';
import 'package:noscall/wallet/domain/wallet_configuration.dart';

void main() {
  test('validates, confirms, toggles, and removes an account Mint', () async {
    final owner = CashuAccountId.fromNostrPubkey('a' * 64);
    final inspector = _Inspector();
    final repository = _Repository();
    final registry = MintRegistryService(
      inspector: inspector,
      repository: repository,
    );
    final controller = AccountMintManagementController(
      accountId: owner,
      registry: registry,
    );

    expect((await controller.load()).mints, isEmpty);
    final preview = await controller.validateManual('https://mint.example.com');
    expect((await controller.confirm(preview)).mints, hasLength(1));

    final disabled = await controller.setEnabled(preview.snapshot.url, false);
    expect(disabled.mints.single.enabled, isFalse);
    final enabled = await controller.setEnabled(preview.snapshot.url, true);
    expect(enabled.mints.single.enabled, isTrue);

    expect((await controller.remove(preview.snapshot.url)).mints, isEmpty);
  });

  test('disposes its owned dependency only once', () async {
    var disposeCalls = 0;
    final controller = AccountMintManagementController(
      accountId: CashuAccountId.fromNostrPubkey('b' * 64),
      registry: MintRegistryService(
        inspector: _Inspector(),
        repository: _Repository(),
      ),
      onDispose: () async => disposeCalls++,
    );

    await controller.dispose();
    await controller.dispose();

    expect(disposeCalls, 1);
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

final class _Inspector implements CashuMintInspector {
  @override
  Future<CashuMintSnapshot> inspectMint(CashuMintUrl mintUrl) async =>
      CashuMintSnapshot(
        url: mintUrl,
        name: 'Test Mint',
        description: 'Test description',
        supportedNuts: _requiredNuts,
        supportsSat: true,
        supportsBolt11Mint: false,
        supportsBolt11Melt: false,
      );
}

final class _Repository implements MintConfigurationRepository {
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
