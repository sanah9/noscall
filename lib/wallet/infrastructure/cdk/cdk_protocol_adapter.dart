import 'dart:async';
import 'dart:convert';

import 'package:cdk/cdk.dart' as cdk;
import 'package:http/http.dart' as http;

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
    required bool hasUsableSatKeyset,
  }) {
    final nuts = info.nuts;
    final supportsBolt11Mint =
        !nuts.nut04.disabled && nuts.nut04.methods.any(_isBolt11SatMintMethod);
    final supportsBolt11Melt =
        !nuts.nut05.disabled && nuts.nut05.methods.any(_isBolt11SatMeltMethod);
    final advertisesSat =
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
      supportsSat: advertisesSat && hasUsableSatKeyset,
      supportsBolt11Mint: supportsBolt11Mint,
      supportsBolt11Melt: supportsBolt11Melt,
      name: info.name,
      description: info.description,
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

/// Reads public Mint metadata and verifies that an active sat keyset has keys.
final class CdkHttpMintInspector implements CashuMintInspector {
  CdkHttpMintInspector({
    required http.Client client,
    this.requestTimeout = const Duration(seconds: 15),
  }) : _client = client;

  final http.Client _client;
  final Duration requestTimeout;

  @override
  Future<CashuMintSnapshot> inspectMint(CashuMintUrl mintUrl) async {
    try {
      final infoPayload = await _getJson(_endpoint(mintUrl, 'v1/info'));
      final info = cdk.decodeMintInfo(json: jsonEncode(infoPayload));
      final keysetsPayload = await _getJson(_endpoint(mintUrl, 'v1/keysets'));
      final keysets = _objectList(keysetsPayload, 'keysets');
      final activeSatIds = keysets
          .where(
            (keyset) => keyset['active'] == true && keyset['unit'] == 'sat',
          )
          .map((keyset) => keyset['id'])
          .whereType<String>()
          .where((id) => id.isNotEmpty);

      var hasUsableSatKeyset = false;
      for (final id in activeSatIds) {
        final keysPayload = await _getJson(
          _endpoint(mintUrl, 'v1/keys/${Uri.encodeComponent(id)}'),
        );
        final matchingKeysets = _objectList(
          keysPayload,
          'keysets',
        ).where((keyset) => keyset['id'] == id && keyset['unit'] == 'sat');
        if (matchingKeysets.any((keyset) => _hasKeys(keyset['keys']))) {
          hasUsableSatKeyset = true;
          break;
        }
      }

      return CdkMintInfoMapper.toSnapshot(
        mintUrl: mintUrl,
        info: info,
        hasUsableSatKeyset: hasUsableSatKeyset,
      );
    } on CashuProtocolException {
      rethrow;
    } on TimeoutException {
      throw const CashuProtocolException(
        'mint_unreachable',
        'The Mint did not respond in time',
      );
    } on http.ClientException {
      throw const CashuProtocolException(
        'mint_unreachable',
        'The Mint could not be reached',
      );
    } catch (_) {
      throw const CashuProtocolException(
        'invalid_mint_response',
        'The Mint returned invalid metadata',
      );
    }
  }

  Uri _endpoint(CashuMintUrl mintUrl, String path) =>
      Uri.parse('${mintUrl.toString()}/$path');

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _client
        .get(uri, headers: const {'accept': 'application/json'})
        .timeout(requestTimeout);
    if (response.statusCode != 200) {
      throw const CashuProtocolException(
        'mint_http_error',
        'The Mint rejected a metadata request',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CashuProtocolException(
        'invalid_mint_response',
        'The Mint returned invalid metadata',
      );
    }
    return decoded;
  }

  List<Map<String, dynamic>> _objectList(
    Map<String, dynamic> payload,
    String field,
  ) {
    final values = payload[field];
    if (values is! List) {
      throw const CashuProtocolException(
        'invalid_mint_response',
        'The Mint returned invalid metadata',
      );
    }
    return values.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  bool _hasKeys(Object? value) => value is Map && value.isNotEmpty;
}
