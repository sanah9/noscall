import 'package:http/http.dart' as http;

import '../../../core/account/account.dart';
import '../../../core/common/database/db_isar.dart';
import '../../application/account_wallet_balance_service.dart';
import '../../application/mint_management_controller.dart';
import '../../application/mint_registry_service.dart';
import '../../application/wallet_session_manager.dart';
import '../../domain/cashu_account_id.dart';
import '../../domain/mint_configuration.dart';
import '../cdk/cdk_protocol_adapter.dart';
import '../database/isar_wallet_configuration_repository.dart';
import 'mobile_account_wallet_factory.dart';

typedef MintManagementControllerFactory =
    Future<MintManagementController> Function();

final class MobileMintManagementControllerFactory {
  const MobileMintManagementControllerFactory._();

  static Future<MintManagementController> create({
    DefaultMintProvider defaultMintProvider = const EmptyDefaultMintProvider(),
  }) async {
    final accountId = CashuAccountId.fromNostrPubkey(
      Account.sharedInstance.currentPubkey,
    );
    final walletFactory = await MobileAccountWalletFactory.create();
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
