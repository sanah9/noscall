import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/application/wallet_recovery_input_controller.dart';

void main() {
  const validMnemonic =
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

  test('normalizes a valid phrase and deduplicates Mint URLs', () {
    const controller = WalletRecoveryInputController(
      mnemonicValidator: _MnemonicValidator(valid: true),
    );

    final draft = controller.validate(
      mnemonicInput: '  ${validMnemonic.toUpperCase()}  ',
      mintUrlsInput:
          'https://MINT.example.com/\nhttps://mint.example.com\nhttps://other.example.com',
    );

    expect(draft.mnemonic, validMnemonic);
    expect(draft.mintUrls.map((url) => url.toString()), [
      'https://mint.example.com',
      'https://other.example.com',
    ]);
  });

  test('rejects an invalid recovery phrase', () {
    const controller = WalletRecoveryInputController(
      mnemonicValidator: _MnemonicValidator(valid: false),
    );

    expect(
      () => controller.validate(
        mnemonicInput: validMnemonic,
        mintUrlsInput: 'https://mint.example.com',
      ),
      throwsA(
        isA<WalletRecoveryInputException>().having(
          (error) => error.message,
          'message',
          contains('valid 12-word'),
        ),
      ),
    );
  });

  test('requires at least one valid HTTPS Mint URL', () {
    const controller = WalletRecoveryInputController(
      mnemonicValidator: _MnemonicValidator(valid: true),
    );

    expect(
      () =>
          controller.validate(mnemonicInput: validMnemonic, mintUrlsInput: ''),
      throwsA(
        isA<WalletRecoveryInputException>().having(
          (error) => error.message,
          'message',
          contains('at least one Mint'),
        ),
      ),
    );
    expect(
      () => controller.validate(
        mnemonicInput: validMnemonic,
        mintUrlsInput: 'http://insecure.example.com',
      ),
      throwsA(isA<WalletRecoveryInputException>()),
    );
  });
}

final class _MnemonicValidator implements WalletMnemonicValidator {
  const _MnemonicValidator({required this.valid});

  final bool valid;

  @override
  bool isValidTwelveWordMnemonic(String mnemonic) => valid;
}
