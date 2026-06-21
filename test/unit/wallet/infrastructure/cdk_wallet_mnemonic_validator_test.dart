import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/infrastructure/cdk/cdk_wallet_mnemonic_validator.dart';

void main() {
  const validator = CdkWalletMnemonicValidator();

  test('accepts a valid 12-word BIP39 phrase', () {
    expect(
      validator.isValidTwelveWordMnemonic(
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      ),
      isTrue,
    );
  });

  test('rejects invalid checksum and word count', () {
    expect(
      validator.isValidTwelveWordMnemonic(
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon',
      ),
      isFalse,
    );
    expect(validator.isValidTwelveWordMnemonic('abandon about'), isFalse);
  });
}
