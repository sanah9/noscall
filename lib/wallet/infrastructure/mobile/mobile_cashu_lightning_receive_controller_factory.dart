import '../../../core/account/account.dart';
import '../../../core/common/database/db_isar.dart';
import '../../application/cashu_lightning_receive_controller.dart';
import '../../application/wallet_session_manager.dart';
import '../../domain/cashu_account_id.dart';
import '../database/isar_wallet_configuration_repository.dart';
import 'mobile_account_wallet_factory.dart';

typedef CashuLightningReceiveControllerFactory =
    Future<CashuLightningReceiveController> Function();

final class MobileCashuLightningReceiveControllerFactory {
  const MobileCashuLightningReceiveControllerFactory._();

  static Future<CashuLightningReceiveController> create() async {
    final accountId = CashuAccountId.fromNostrPubkey(
      Account.sharedInstance.currentPubkey,
    );
    final walletFactory = await MobileAccountWalletFactory.create();
    return AccountCashuLightningReceiveController(
      accountId: accountId,
      sessionManager: WalletSessionManager(factory: walletFactory),
      mintRepository: IsarMintConfigurationRepository(
        DBISAR.sharedInstance.isar,
      ),
      quoteRepository: IsarCashuLightningReceiveQuoteRepository(
        DBISAR.sharedInstance.isar,
      ),
    );
  }
}
