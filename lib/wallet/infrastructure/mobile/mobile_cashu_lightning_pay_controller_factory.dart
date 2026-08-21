import '../../../core/account/account.dart';
import '../../../core/common/database/db_isar.dart';
import '../../application/cashu_lightning_pay_controller.dart';
import '../../application/wallet_session_manager.dart';
import '../../domain/cashu_account_id.dart';
import '../database/isar_wallet_configuration_repository.dart';
import 'mobile_account_wallet_factory.dart';

typedef CashuLightningPayControllerFactory =
    Future<CashuLightningPayController> Function();

final class MobileCashuLightningPayControllerFactory {
  const MobileCashuLightningPayControllerFactory._();

  static Future<CashuLightningPayController> create() async {
    final accountId = CashuAccountId.fromNostrPubkey(
      Account.sharedInstance.currentPubkey,
    );
    final walletFactory = await MobileAccountWalletFactory.create();
    return AccountCashuLightningPayController(
      accountId: accountId,
      sessionManager: WalletSessionManager(factory: walletFactory),
      mintRepository: IsarMintConfigurationRepository(
        DBISAR.sharedInstance.isar,
      ),
      quoteRepository: IsarCashuLightningPayQuoteRepository(
        DBISAR.sharedInstance.isar,
      ),
    );
  }
}
