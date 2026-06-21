import 'package:http/http.dart' as http;

import '../../../core/account/account.dart';
import '../../../core/common/database/db_isar.dart';
import '../../application/mint_management_controller.dart';
import '../../application/mint_registry_service.dart';
import '../../domain/cashu_account_id.dart';
import '../../domain/mint_configuration.dart';
import '../cdk/cdk_protocol_adapter.dart';
import '../database/isar_wallet_configuration_repository.dart';

typedef MintManagementControllerFactory =
    Future<MintManagementController> Function();

final class MobileMintManagementControllerFactory {
  const MobileMintManagementControllerFactory._();

  static Future<MintManagementController> create({
    DefaultMintProvider defaultMintProvider = const EmptyDefaultMintProvider(),
  }) async {
    final client = http.Client();
    final registry = MintRegistryService(
      inspector: CdkHttpMintInspector(client: client),
      repository: IsarMintConfigurationRepository(DBISAR.sharedInstance.isar),
      defaultMintProvider: defaultMintProvider,
    );
    return AccountMintManagementController(
      accountId: CashuAccountId.fromNostrPubkey(
        Account.sharedInstance.currentPubkey,
      ),
      registry: registry,
      onDispose: () async => client.close(),
    );
  }
}
