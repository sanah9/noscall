import '../../application/mint_management_controller.dart';
import '../../domain/mint_configuration.dart';
import '../default_mint_management_controller_factory.dart'
    show DefaultMintManagementControllerFactory;

typedef MintManagementControllerFactory =
    Future<MintManagementController> Function();

@Deprecated(
  'Use DefaultMintManagementControllerFactory; it supports mobile and desktop.',
)
final class MobileMintManagementControllerFactory {
  const MobileMintManagementControllerFactory._();

  static Future<MintManagementController> create({
    DefaultMintProvider defaultMintProvider = const EmptyDefaultMintProvider(),
  }) async {
    return DefaultMintManagementControllerFactory.create(
      defaultMintProvider: defaultMintProvider,
    );
  }
}
