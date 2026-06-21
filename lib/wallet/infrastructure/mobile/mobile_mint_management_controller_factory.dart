import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../core/account/account.dart';
import '../../../core/common/database/db_isar.dart';
import '../../application/account_wallet_balance_service.dart';
import '../../application/mint_management_controller.dart';
import '../../application/mint_registry_service.dart';
import '../../application/wallet_session_manager.dart';
import '../../domain/cashu_account_id.dart';
import '../../domain/mint_configuration.dart';
import '../cdk/cdk_protocol_adapter.dart';
import '../cdk/cdk_account_wallet.dart';
import '../database/isar_wallet_configuration_repository.dart';
import '../security/development_file_wallet_key_store.dart';

typedef MintManagementControllerFactory =
    Future<MintManagementController> Function();

final class MobileMintManagementControllerFactory {
  const MobileMintManagementControllerFactory._();

  static Future<MintManagementController> create({
    DefaultMintProvider defaultMintProvider = const EmptyDefaultMintProvider(),
  }) async {
    if (!kDebugMode) {
      throw StateError('Secure wallet storage is required to read balances.');
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
    final balanceService = AccountWalletBalanceService(
      accountId: accountId,
      sessionManager: WalletSessionManager(factory: walletFactory),
    );
    final client = http.Client();
    final registry = MintRegistryService(
      inspector: CdkHttpMintInspector(client: client),
      repository: IsarMintConfigurationRepository(DBISAR.sharedInstance.isar),
      defaultMintProvider: defaultMintProvider,
    );
    return AccountMintManagementController(
      accountId: accountId,
      registry: registry,
      balanceService: balanceService,
      onDispose: () async => client.close(),
    );
  }
}
