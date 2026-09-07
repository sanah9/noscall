import '../../application/cashu_lightning_pay_controller.dart';
import '../default_cashu_lightning_pay_controller_factory.dart'
    show DefaultCashuLightningPayControllerFactory;

typedef CashuLightningPayControllerFactory =
    Future<CashuLightningPayController> Function();

@Deprecated(
  'Use DefaultCashuLightningPayControllerFactory; it supports mobile and desktop.',
)
final class MobileCashuLightningPayControllerFactory {
  const MobileCashuLightningPayControllerFactory._();

  static Future<CashuLightningPayController> create() async {
    return DefaultCashuLightningPayControllerFactory.create();
  }
}
