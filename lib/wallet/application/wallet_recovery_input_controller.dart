import '../domain/cashu_models.dart';

abstract interface class WalletMnemonicValidator {
  bool isValidTwelveWordMnemonic(String mnemonic);
}

final class WalletRecoveryDraft {
  WalletRecoveryDraft({
    required this.mnemonic,
    required Iterable<CashuMintUrl> mintUrls,
  }) : mintUrls = List.unmodifiable(mintUrls);

  final String mnemonic;
  final List<CashuMintUrl> mintUrls;
}

final class WalletRecoveryInputException implements Exception {
  const WalletRecoveryInputException(this.message);

  final String message;
}

final class WalletRecoveryInputController {
  const WalletRecoveryInputController({
    required WalletMnemonicValidator mnemonicValidator,
  }) : _mnemonicValidator = mnemonicValidator;

  final WalletMnemonicValidator _mnemonicValidator;

  WalletRecoveryDraft validate({
    required String mnemonicInput,
    required String mintUrlsInput,
  }) {
    final words = mnemonicInput.trim().toLowerCase().split(RegExp(r'\s+'));
    final mnemonic = words.join(' ');
    if (words.length != 12 ||
        !_mnemonicValidator.isValidTwelveWordMnemonic(mnemonic)) {
      throw const WalletRecoveryInputException(
        'Enter a valid 12-word wallet recovery phrase.',
      );
    }

    final mintValues = mintUrlsInput
        .split(RegExp(r'[\r\n]+'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty);
    final mintUrls = <CashuMintUrl>[];
    final seen = <CashuMintUrl>{};
    for (final value in mintValues) {
      try {
        final url = CashuMintUrl.parse(value);
        if (seen.add(url)) mintUrls.add(url);
      } on FormatException {
        throw const WalletRecoveryInputException(
          'Every Mint must be a valid HTTPS URL, one per line.',
        );
      }
    }
    if (mintUrls.isEmpty) {
      throw const WalletRecoveryInputException(
        'Add at least one Mint previously used by this wallet.',
      );
    }

    return WalletRecoveryDraft(mnemonic: mnemonic, mintUrls: mintUrls);
  }
}
