import 'package:cdk/cdk.dart' as cdk;

import '../../application/wallet_recovery_input_controller.dart';

final class CdkWalletMnemonicValidator implements WalletMnemonicValidator {
  const CdkWalletMnemonicValidator();

  @override
  bool isValidTwelveWordMnemonic(String mnemonic) {
    try {
      return mnemonic.trim().split(RegExp(r'\s+')).length == 12 &&
          cdk.mnemonicToEntropy(mnemonic: mnemonic).length == 16;
    } catch (_) {
      return false;
    }
  }
}
