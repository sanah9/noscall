import 'package:cdk/cdk.dart' as cdk;

import '../../domain/cashu_engine.dart';
import '../../domain/cashu_models.dart';
import '../../domain/wallet_errors.dart';

/// Stateless CDK-backed protocol operations that do not mutate a wallet.
final class CdkTokenCodec implements CashuTokenCodec {
  const CdkTokenCodec({this.allowInsecureMintUrls = false});

  final bool allowInsecureMintUrls;

  @override
  CashuTokenSummary decodeToken(String encodedToken) {
    cdk.Token? token;
    try {
      final normalizedToken = encodedToken.trim();
      final version = _tokenVersion(normalizedToken);
      token = cdk.Token.decode(encodedToken: normalizedToken);
      if (token.unit() is! cdk.SatCurrencyUnit) {
        throw const CashuProtocolException(
          'unsupported_unit',
          'Only sat-denominated Cashu tokens are supported',
        );
      }

      return CashuTokenSummary(
        encodedToken: normalizedToken,
        mintUrl: CashuMintUrl.parse(
          token.mintUrl().url,
          allowInsecureHttp: allowInsecureMintUrls,
        ),
        amount: CashuAmount.positiveSats(token.value().value),
        version: version,
        memo: token.memo(),
      );
    } on CashuProtocolException {
      rethrow;
    } on FormatException {
      throw const CashuProtocolException(
        'invalid_mint_url',
        'The token contains an invalid or insecure Mint URL',
      );
    } catch (_) {
      throw const CashuProtocolException(
        'invalid_token',
        'The Cashu token is invalid or unsupported',
      );
    } finally {
      token?.dispose();
    }
  }

  int _tokenVersion(String encodedToken) {
    if (encodedToken.startsWith('cashuB')) return 4;
    if (encodedToken.startsWith('cashuA')) return 3;
    throw const CashuProtocolException(
      'invalid_token_prefix',
      'The Cashu token prefix is invalid',
    );
  }
}

/// Converts CDK Mint Info into the stable domain capability model.
final class CdkMintInfoMapper {
  const CdkMintInfoMapper._();

  static CashuMintSnapshot toSnapshot({
    required CashuMintUrl mintUrl,
    required cdk.MintInfo info,
  }) {
    final nuts = info.nuts;
    final supportsBolt11Mint =
        !nuts.nut04.disabled && nuts.nut04.methods.any(_isBolt11SatMintMethod);
    final supportsBolt11Melt =
        !nuts.nut05.disabled && nuts.nut05.methods.any(_isBolt11SatMeltMethod);
    final supportsSat =
        nuts.mintUnits.any(_isSat) ||
        nuts.meltUnits.any(_isSat) ||
        nuts.nut04.methods.any((method) => _isSat(method.unit)) ||
        nuts.nut05.methods.any((method) => _isSat(method.unit));

    final supportedNuts = <CashuNut>{
      CashuNut.nut00,
      CashuNut.nut01,
      CashuNut.nut02,
      CashuNut.nut03,
      CashuNut.nut06,
      if (!nuts.nut04.disabled && nuts.nut04.methods.isNotEmpty) CashuNut.nut04,
      if (!nuts.nut05.disabled && nuts.nut05.methods.isNotEmpty) CashuNut.nut05,
      if (nuts.nut07Supported) CashuNut.nut07,
      if (nuts.nut08Supported) CashuNut.nut08,
      if (nuts.nut09Supported) CashuNut.nut09,
      if (nuts.nut12Supported) CashuNut.nut12,
      if (supportsBolt11Mint || supportsBolt11Melt) CashuNut.nut23,
    };

    return CashuMintSnapshot(
      url: mintUrl,
      supportedNuts: supportedNuts,
      supportsSat: supportsSat,
      supportsBolt11Mint: supportsBolt11Mint,
      supportsBolt11Melt: supportsBolt11Melt,
      name: info.name,
      version: switch (info.version) {
        final version? => '${version.name}/${version.version}',
        null => null,
      },
    );
  }

  static bool _isBolt11SatMintMethod(cdk.MintMethodSettings method) =>
      method.method is cdk.Bolt11PaymentMethod && _isSat(method.unit);

  static bool _isBolt11SatMeltMethod(cdk.MeltMethodSettings method) =>
      method.method is cdk.Bolt11PaymentMethod && _isSat(method.unit);

  static bool _isSat(cdk.CurrencyUnit unit) => unit is cdk.SatCurrencyUnit;
}
