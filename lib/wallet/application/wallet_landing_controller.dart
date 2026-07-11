import '../domain/cashu_account_id.dart';
import '../domain/cashu_models.dart';
import '../domain/wallet_configuration.dart';
import 'wallet_configuration_service.dart';
import 'wallet_session_manager.dart';

enum WalletLandingStatus { absent, ready, unavailable }

final class WalletLandingSnapshot {
  const WalletLandingSnapshot._({
    required this.status,
    required this.balanceSats,
    required this.backupStatus,
    required this.mintCount,
    required this.enabledMintCount,
    required this.reconciliationResult,
    this.unavailableReason,
  });

  const WalletLandingSnapshot.absent()
    : this._(
        status: WalletLandingStatus.absent,
        balanceSats: 0,
        backupStatus: null,
        mintCount: 0,
        enabledMintCount: 0,
        reconciliationResult: null,
      );

  const WalletLandingSnapshot.unavailable(String reason)
    : this._(
        status: WalletLandingStatus.unavailable,
        balanceSats: 0,
        backupStatus: null,
        mintCount: 0,
        enabledMintCount: 0,
        reconciliationResult: null,
        unavailableReason: reason,
      );

  const WalletLandingSnapshot.ready({
    required int balanceSats,
    required WalletBackupStatus backupStatus,
    required int mintCount,
    required int enabledMintCount,
    required CashuReconciliationResult reconciliationResult,
  }) : this._(
         status: WalletLandingStatus.ready,
         balanceSats: balanceSats,
         backupStatus: backupStatus,
         mintCount: mintCount,
         enabledMintCount: enabledMintCount,
         reconciliationResult: reconciliationResult,
       );

  final WalletLandingStatus status;
  final int balanceSats;
  final WalletBackupStatus? backupStatus;
  final int mintCount;
  final int enabledMintCount;
  final CashuReconciliationResult? reconciliationResult;
  final String? unavailableReason;
}

abstract interface class WalletLandingController {
  bool get isDevelopmentOnly;

  Future<WalletLandingSnapshot> load();

  Future<WalletLandingSnapshot> refresh();

  Future<String> createWallet();

  Future<WalletLandingSnapshot> updateBackupStatus(WalletBackupStatus status);

  Future<void> closeSession();

  Future<void> dispose();
}

final class AccountWalletLandingController implements WalletLandingController {
  AccountWalletLandingController({
    required CashuAccountId accountId,
    required WalletSessionManager sessionManager,
    required WalletConfigurationService configurationService,
    required MintConfigurationRepository mintRepository,
    required this.isDevelopmentOnly,
  }) : _accountId = accountId,
       _sessionManager = sessionManager,
       _configurationService = configurationService,
       _mintRepository = mintRepository;

  final CashuAccountId _accountId;
  final WalletSessionManager _sessionManager;
  final WalletConfigurationService _configurationService;
  final MintConfigurationRepository _mintRepository;

  @override
  final bool isDevelopmentOnly;

  @override
  Future<WalletLandingSnapshot> load() async {
    final session = await _sessionManager.activate(_accountId);
    return _snapshotFromSession(session);
  }

  @override
  Future<WalletLandingSnapshot> refresh() async {
    final session = await _sessionManager.recoverActive(_accountId);
    return _snapshotFromSession(session);
  }

  Future<WalletLandingSnapshot> _snapshotFromSession(
    WalletSessionState session,
  ) async {
    final wallet = session.wallet;
    if (wallet == null) return const WalletLandingSnapshot.absent();

    final configuration = await _configurationService.ensure(_accountId);
    final mints = await _mintRepository.list(_accountId);
    return WalletLandingSnapshot.ready(
      balanceSats: await wallet.totalBalanceSats(),
      backupStatus: configuration.backupStatus,
      mintCount: mints.length,
      enabledMintCount: mints.where((mint) => mint.enabled).length,
      reconciliationResult:
          session.reconciliationResult ??
          const CashuReconciliationResult(
            recoveredOperations: 0,
            pendingOperations: 0,
          ),
    );
  }

  @override
  Future<String> createWallet() async {
    final creation = await _sessionManager.create(_accountId);
    await _configurationService.ensure(_accountId);
    return creation.mnemonic;
  }

  @override
  Future<WalletLandingSnapshot> updateBackupStatus(
    WalletBackupStatus status,
  ) async {
    await _configurationService.updateBackupStatus(_accountId, status);
    return load();
  }

  @override
  Future<void> closeSession() => _sessionManager.closeActive();

  @override
  Future<void> dispose() => _sessionManager.dispose();
}

final class UnavailableWalletLandingController
    implements WalletLandingController {
  const UnavailableWalletLandingController(this.reason);

  final String reason;

  @override
  bool get isDevelopmentOnly => false;

  @override
  Future<WalletLandingSnapshot> load() async =>
      WalletLandingSnapshot.unavailable(reason);

  @override
  Future<WalletLandingSnapshot> refresh() async =>
      WalletLandingSnapshot.unavailable(reason);

  @override
  Future<String> createWallet() => Future.error(StateError(reason));

  @override
  Future<WalletLandingSnapshot> updateBackupStatus(WalletBackupStatus status) =>
      Future.error(StateError(reason));

  @override
  Future<void> closeSession() async {}

  @override
  Future<void> dispose() async {}
}
