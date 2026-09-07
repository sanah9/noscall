import '../../application/wallet_landing_controller.dart';
import '../default_wallet_controller_factory.dart'
    show DefaultWalletControllerFactory;

typedef WalletLandingControllerFactory =
    Future<WalletLandingController> Function();

@Deprecated(
  'Use DefaultWalletControllerFactory; it supports mobile and desktop.',
)
final class MobileWalletControllerFactory {
  const MobileWalletControllerFactory._();

  static Future<WalletLandingController> create() async {
    return DefaultWalletControllerFactory.create();
  }
}
