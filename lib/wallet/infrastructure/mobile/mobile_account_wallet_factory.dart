import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../cdk/cdk_account_wallet.dart';
import '../security/account_secret_wallet_key_store.dart';
import '../security/development_file_wallet_key_store.dart';

final class MobileAccountWalletFactory {
  const MobileAccountWalletFactory._();

  static Future<CdkAccountWalletFactory> create() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final walletRoot = Directory('${supportDirectory.path}/cashu');
    if (kDebugMode) {
      return CdkAccountWalletFactory(
        walletsRoot: Directory('${walletRoot.path}/accounts'),
        keyStore: DevelopmentFileWalletKeyStore(
          Directory('${walletRoot.path}/development-seeds'),
        ),
        allowInsecureDevelopmentStore: true,
      );
    }

    return CdkAccountWalletFactory(
      walletsRoot: Directory('${walletRoot.path}/accounts'),
      keyStore: const AccountSecretWalletKeyStore(),
    );
  }
}
