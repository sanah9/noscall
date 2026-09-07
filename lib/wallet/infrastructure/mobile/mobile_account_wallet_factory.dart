import '../cdk/cdk_account_wallet.dart';
import '../default_account_wallet_factory.dart';

@Deprecated('Use DefaultAccountWalletFactory; it supports mobile and desktop.')
final class MobileAccountWalletFactory {
  const MobileAccountWalletFactory._();

  static Future<CdkAccountWalletFactory> create() async {
    return DefaultAccountWalletFactory.create();
  }
}
