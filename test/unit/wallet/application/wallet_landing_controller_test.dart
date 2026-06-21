import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/application/wallet_configuration_service.dart';
import 'package:noscall/wallet/application/wallet_landing_controller.dart';
import 'package:noscall/wallet/application/wallet_session_manager.dart';
import 'package:noscall/wallet/domain/account_wallet.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';
import 'package:noscall/wallet/domain/wallet_configuration.dart';

void main() {
  late CashuAccountId account;
  late _FakeWalletFactory walletFactory;
  late _MemoryWalletConfigurationRepository repository;
  late AccountWalletLandingController controller;

  setUp(() {
    account = CashuAccountId.fromNostrPubkey('a' * 64);
    walletFactory = _FakeWalletFactory();
    repository = _MemoryWalletConfigurationRepository();
    controller = AccountWalletLandingController(
      accountId: account,
      sessionManager: WalletSessionManager(factory: walletFactory),
      configurationService: WalletConfigurationService(
        repository: repository,
        clock: () => DateTime.utc(2026, 6, 21),
      ),
      isDevelopmentOnly: true,
    );
  });

  tearDown(() => controller.dispose());

  test('loads absent state without creating a wallet', () async {
    final snapshot = await controller.load();

    expect(snapshot.status, WalletLandingStatus.absent);
    expect(walletFactory.createCalls, 0);
    expect(await repository.find(account), isNull);
  });

  test(
    'creates wallet and persists backup state for the same account',
    () async {
      final mnemonic = await controller.createWallet();
      final shown = await controller.updateBackupStatus(
        WalletBackupStatus.shown,
      );
      final skipped = await controller.updateBackupStatus(
        WalletBackupStatus.skipped,
      );

      expect(mnemonic, _FakeWalletFactory.mnemonic);
      expect(shown.status, WalletLandingStatus.ready);
      expect(shown.backupStatus, WalletBackupStatus.shown);
      expect(skipped.backupStatus, WalletBackupStatus.skipped);
      expect(walletFactory.wallet?.recoveryCalls, 0);
      expect((await repository.find(account))?.owner, account);
    },
  );
}

final class _FakeWalletFactory implements AccountWalletFactory {
  static const mnemonic =
      'abandon ability able about above absent absorb abstract absurd abuse access accident';

  _FakeWallet? wallet;
  int createCalls = 0;

  @override
  Future<bool> exists(CashuAccountId accountId) async => wallet != null;

  @override
  Future<AccountWalletCreation<AccountWalletSession>> createNew(
    CashuAccountId accountId,
  ) async {
    createCalls++;
    final created = wallet = _FakeWallet(accountId);
    return AccountWalletCreation(wallet: created, mnemonic: mnemonic);
  }

  @override
  Future<AccountWalletSession> openExisting(CashuAccountId accountId) async =>
      wallet!;
}

final class _FakeWallet implements AccountWalletSession {
  _FakeWallet(this.accountId);

  @override
  final CashuAccountId accountId;
  int recoveryCalls = 0;

  @override
  Future<void> close() async {}

  @override
  Future<CashuReconciliationResult> reconcilePendingOperations() async {
    recoveryCalls++;
    return const CashuReconciliationResult(
      recoveredOperations: 0,
      pendingOperations: 0,
    );
  }

  @override
  Future<int> totalBalanceSats() async => 0;
}

final class _MemoryWalletConfigurationRepository
    implements WalletConfigurationRepository {
  final Map<CashuAccountId, WalletConfiguration> values = {};

  @override
  Future<WalletConfiguration?> find(CashuAccountId owner) async =>
      values[owner];

  @override
  Future<void> save(WalletConfiguration configuration) async {
    values[configuration.owner] = configuration;
  }
}
