import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/application/account_wallet_balance_service.dart';
import 'package:noscall/wallet/application/mint_management_controller.dart';
import 'package:noscall/wallet/application/mint_registry_service.dart';
import 'package:noscall/wallet/application/wallet_session_manager.dart';
import 'package:noscall/wallet/domain/account_wallet.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_engine.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';
import 'package:noscall/wallet/domain/wallet_configuration.dart';
import 'package:noscall/wallet/domain/wallet_errors.dart';

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
      balanceService: _balanceService(owner),
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
      balanceService: _balanceService(CashuAccountId.fromNostrPubkey('b' * 64)),
      onDispose: () async => disposeCalls++,
    );

    await controller.dispose();
    await controller.dispose();

    expect(disposeCalls, 1);
  });

  test('does not remove a Mint that still has a local balance', () async {
    final owner = CashuAccountId.fromNostrPubkey('c' * 64);
    final inspector = _Inspector();
    final repository = _Repository();
    final registry = MintRegistryService(
      inspector: inspector,
      repository: repository,
    );
    final url = CashuMintUrl.parse('https://mint.example.com');
    await registry.confirm(
      await registry.validateManual(owner, url.toString()),
    );
    final controller = AccountMintManagementController(
      accountId: owner,
      registry: registry,
      balanceService: _balanceService(owner, balances: {url: 42}),
    );

    final snapshot = await controller.load();
    expect(snapshot.balanceFor(url), 42);
    await expectLater(
      controller.remove(url),
      throwsA(
        isA<MintHasBalanceException>().having(
          (error) => error.balanceSats,
          'balance',
          42,
        ),
      ),
    );
    expect(await repository.find(owner, url), isNotNull);
  });
}

AccountWalletBalanceService _balanceService(
  CashuAccountId owner, {
  Map<CashuMintUrl, int> balances = const {},
}) => AccountWalletBalanceService(
  accountId: owner,
  sessionManager: WalletSessionManager(
    factory: _BalanceWalletFactory(_BalanceWallet(owner, balances)),
  ),
);

final class _BalanceWalletFactory implements AccountWalletFactory {
  const _BalanceWalletFactory(this.wallet);

  final _BalanceWallet wallet;

  @override
  Future<bool> exists(CashuAccountId accountId) async => true;

  @override
  Future<AccountWalletSession> openExisting(CashuAccountId accountId) async =>
      wallet;

  @override
  Future<AccountWalletCreation<AccountWalletSession>> createNew(
    CashuAccountId accountId,
  ) => throw UnimplementedError();
}

final class _BalanceWallet implements AccountWalletSession {
  _BalanceWallet(this.accountId, this.balances);

  @override
  final CashuAccountId accountId;
  final Map<CashuMintUrl, int> balances;

  @override
  Future<Map<CashuMintUrl, int>> balancesByMintSats() async => balances;

  @override
  Future<int> totalBalanceSats() async =>
      balances.values.fold<int>(0, (total, balance) => total + balance);

  @override
  Future<CashuReconciliationResult> reconcilePendingOperations() async =>
      const CashuReconciliationResult(
        recoveredOperations: 0,
        pendingOperations: 0,
      );

  @override
  Future<CashuReceiveResult> receive(CashuReceiveRequest request) =>
      throw UnimplementedError();

  @override
  Future<CashuPreparedSend> prepareSend(CashuSendRequest request) =>
      throw UnimplementedError();

  @override
  Future<CashuSendState> checkSendStatus({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) => throw UnimplementedError();

  @override
  Future<CashuAmount> reclaimSend({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) => throw UnimplementedError();

  @override
  Future<void> close() async {}
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
