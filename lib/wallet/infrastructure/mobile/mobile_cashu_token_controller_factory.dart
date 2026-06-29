import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/account/account.dart';
import '../../../core/common/database/db_isar.dart';
import '../../application/cashu_token_controller.dart';
import '../../application/wallet_session_manager.dart';
import '../../domain/cashu_account_id.dart';
import '../cdk/cdk_account_wallet.dart';
import '../cdk/cdk_protocol_adapter.dart';
import '../database/isar_wallet_configuration_repository.dart';
import '../security/development_file_wallet_key_store.dart';

typedef CashuTokenControllerFactory = Future<CashuTokenController> Function();

final class MobileCashuTokenControllerFactory {
  const MobileCashuTokenControllerFactory._();

  static Future<CashuTokenController> create() async {
    if (!kDebugMode) {
      throw StateError(
        'Secure wallet storage is required to use Cashu tokens.',
      );
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
    return AccountCashuTokenController(
      accountId: accountId,
      sessionManager: WalletSessionManager(factory: walletFactory),
      mintRepository: IsarMintConfigurationRepository(
        DBISAR.sharedInstance.isar,
      ),
      tokenCodec: const CdkTokenCodec(),
    );
  }
}
