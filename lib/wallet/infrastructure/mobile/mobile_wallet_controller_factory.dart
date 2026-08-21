import 'package:flutter/foundation.dart';

import '../../../core/account/account.dart';
import '../../../core/common/database/db_isar.dart';
import '../../application/wallet_configuration_service.dart';
import '../../application/wallet_landing_controller.dart';
import '../../application/wallet_session_manager.dart';
import '../../domain/cashu_account_id.dart';
import '../database/isar_wallet_configuration_repository.dart';
import 'mobile_account_wallet_factory.dart';

typedef WalletLandingControllerFactory =
    Future<WalletLandingController> Function();

final class MobileWalletControllerFactory {
  const MobileWalletControllerFactory._();

  static Future<WalletLandingController> create() async {
    final accountId = CashuAccountId.fromNostrPubkey(
      Account.sharedInstance.currentPubkey,
    );
    final walletFactory = await MobileAccountWalletFactory.create();
    final sessionManager = WalletSessionManager(factory: walletFactory);
    final configurationService = WalletConfigurationService(
      repository: IsarWalletConfigurationRepository(DBISAR.sharedInstance.isar),
    );
    return AccountWalletLandingController(
      accountId: accountId,
      sessionManager: sessionManager,
      configurationService: configurationService,
      mintRepository: IsarMintConfigurationRepository(
        DBISAR.sharedInstance.isar,
      ),
      isDevelopmentOnly: kDebugMode,
    );
  }
}
