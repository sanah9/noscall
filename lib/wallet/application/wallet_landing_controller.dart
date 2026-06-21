import '../domain/cashu_account_id.dart';
import '../domain/wallet_configuration.dart';
import 'wallet_configuration_service.dart';
import 'wallet_session_manager.dart';

enum WalletLandingStatus { absent, ready, unavailable }

final class WalletLandingSnapshot {
  const WalletLandingSnapshot._({
    required this.status,
    required this.balanceSats,
    required this.backupStatus,
    this.unavailableReason,
  });

  const WalletLandingSnapshot.absent()
    : this._(
        status: WalletLandingStatus.absent,
        balanceSats: 0,
        backupStatus: null,
      );

  const WalletLandingSnapshot.unavailable(String reason)
    : this._(
        status: WalletLandingStatus.unavailable,
        balanceSats: 0,
        backupStatus: null,
        unavailableReason: reason,
      );

  const WalletLandingSnapshot.ready({
    required int balanceSats,
    required WalletBackupStatus backupStatus,
  }) : this._(
         status: WalletLandingStatus.ready,
         balanceSats: balanceSats,
         backupStatus: backupStatus,
       );

  final WalletLandingStatus status;
  final int balanceSats;
  final WalletBackupStatus? backupStatus;
  final String? unavailableReason;
}

abstract interface class WalletLandingController {
  bool get isDevelopmentOnly;

  Future<WalletLandingSnapshot> load();

  Future<String> createWallet();

  Future<WalletLandingSnapshot> updateBackupStatus(WalletBackupStatus status);

  Future<void> dispose();
}

final class AccountWalletLandingController implements WalletLandingController {
  AccountWalletLandingController({
    required CashuAccountId accountId,
    required WalletSessionManager sessionManager,
    required WalletConfigurationService configurationService,
    required this.isDevelopmentOnly,
  }) : _accountId = accountId,
       _sessionManager = sessionManager,
       _configurationService = configurationService;

  final CashuAccountId _accountId;
  final WalletSessionManager _sessionManager;
  final WalletConfigurationService _configurationService;

  @override
  final bool isDevelopmentOnly;

  @override
  Future<WalletLandingSnapshot> load() async {
    final session = await _sessionManager.activate(_accountId);
    final wallet = session.wallet;
    if (wallet == null) return const WalletLandingSnapshot.absent();

    final configuration = await _configurationService.ensure(_accountId);
    return WalletLandingSnapshot.ready(
      balanceSats: await wallet.totalBalanceSats(),
      backupStatus: configuration.backupStatus,
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
  Future<String> createWallet() => Future.error(StateError(reason));

  @override
  Future<WalletLandingSnapshot> updateBackupStatus(WalletBackupStatus status) =>
      Future.error(StateError(reason));

  @override
  Future<void> dispose() async {}
}
