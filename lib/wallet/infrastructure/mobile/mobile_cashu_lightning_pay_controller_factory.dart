import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/account/account.dart';
import '../../../core/common/database/db_isar.dart';
import '../../application/cashu_lightning_pay_controller.dart';
import '../../application/wallet_session_manager.dart';
import '../../domain/cashu_account_id.dart';
import '../cdk/cdk_account_wallet.dart';
import '../database/isar_wallet_configuration_repository.dart';
import '../security/development_file_wallet_key_store.dart';

typedef CashuLightningPayControllerFactory =
    Future<CashuLightningPayController> Function();

final class MobileCashuLightningPayControllerFactory {
  const MobileCashuLightningPayControllerFactory._();

  static Future<CashuLightningPayController> create() async {
    if (!kDebugMode) {
      throw StateError('Secure wallet storage is required to pay Lightning.');
    }

    final accountId = CashuAccountId.fromNostrPubkey(
      Account.sharedInstance.currentPubkey,
    );
    final supportDirectory = await getApplicationSupportDirectory();
    final walletRoot = Directory('${supportDirectory.path}/cashu');
    final walletFactory = CdkAccountWalletFactory(
      walletsRoot: Directory('${walletRoot.path}/accounts'),
      keyStore: DevelopmentFileWalletKeyStore(
        Directory('${walletRoot.path}/development-seeds'),
      ),
      allowInsecureDevelopmentStore: true,
    );
    return AccountCashuLightningPayController(
      accountId: accountId,
      sessionManager: WalletSessionManager(factory: walletFactory),
      mintRepository: IsarMintConfigurationRepository(
        DBISAR.sharedInstance.isar,
      ),
    );
  }
}
