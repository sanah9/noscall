import '../../application/cashu_token_controller.dart';
import '../default_cashu_token_controller_factory.dart'
    show DefaultCashuTokenControllerFactory;

typedef CashuTokenControllerFactory = Future<CashuTokenController> Function();

@Deprecated(
  'Use DefaultCashuTokenControllerFactory; it supports mobile and desktop.',
)
final class MobileCashuTokenControllerFactory {
  const MobileCashuTokenControllerFactory._();

  static Future<CashuTokenController> create() async {
    return DefaultCashuTokenControllerFactory.create();
  }
}
