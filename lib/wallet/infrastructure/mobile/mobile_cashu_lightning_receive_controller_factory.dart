import '../../application/cashu_lightning_receive_controller.dart';
import '../default_cashu_lightning_receive_controller_factory.dart'
    show DefaultCashuLightningReceiveControllerFactory;

typedef CashuLightningReceiveControllerFactory =
    Future<CashuLightningReceiveController> Function();

@Deprecated(
  'Use DefaultCashuLightningReceiveControllerFactory; it supports mobile and desktop.',
)
final class MobileCashuLightningReceiveControllerFactory {
  const MobileCashuLightningReceiveControllerFactory._();

  static Future<CashuLightningReceiveController> create() async {
    return DefaultCashuLightningReceiveControllerFactory.create();
  }
}
