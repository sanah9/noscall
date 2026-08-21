import '../../../core/account/account.dart';
import '../../../core/common/database/db_isar.dart';
import '../../application/cashu_token_controller.dart';
import '../../application/wallet_session_manager.dart';
import '../../domain/cashu_account_id.dart';
import '../cdk/cdk_protocol_adapter.dart';
import '../database/isar_wallet_configuration_repository.dart';
import 'mobile_account_wallet_factory.dart';

typedef CashuTokenControllerFactory = Future<CashuTokenController> Function();

final class MobileCashuTokenControllerFactory {
  const MobileCashuTokenControllerFactory._();

  static Future<CashuTokenController> create() async {
    final accountId = CashuAccountId.fromNostrPubkey(
      Account.sharedInstance.currentPubkey,
    );
    final walletFactory = await MobileAccountWalletFactory.create();
    return AccountCashuTokenController(
      accountId: accountId,
      sessionManager: WalletSessionManager(factory: walletFactory),
      mintRepository: IsarMintConfigurationRepository(
        DBISAR.sharedInstance.isar,
      ),
      sendRepository: IsarCashuTokenSendRepository(DBISAR.sharedInstance.isar),
      tokenCodec: const CdkTokenCodec(),
    );
  }
}
