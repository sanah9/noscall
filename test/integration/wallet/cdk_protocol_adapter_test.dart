import 'package:cdk/cdk.dart' as cdk;
import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';
import 'package:noscall/wallet/domain/wallet_errors.dart';
import 'package:noscall/wallet/infrastructure/cdk/cdk_protocol_adapter.dart';

void main() {
  group('CdkTokenCodec', () {
    // Cashu NUT-00 official vector, repository commit
    // fa2f9135c233650eb8c47ac4aa0b75c380f5ec92, tests/00-tests.md.
    const officialNut00V4Token =
        'cashuBpGF0gaJhaUgArSaMTR9YJmFwgaNhYQFhc3hAOWE2ZGJiODQ3YmQyMzJiYTc2ZGIwZGYxOTcyMTZiMjlkM2I4Y2MxNDU1M2NkMjc4MjdmYzFjYzk0MmZlZGI0ZWFjWCEDhhhUP_trhpXfStS6vN6So0qWvc2X3O4NfM-Y1HISZ5JhZGlUaGFuayB5b3VhbXVodHRwOi8vbG9jYWxob3N0OjMzMzhhdWNzYXQ=';

    test('decodes the official NUT-00 V4 token vector', () {
      const codec = CdkTokenCodec(allowInsecureMintUrls: true);

      final summary = codec.decodeToken(officialNut00V4Token);

      expect(summary.version, 4);
      expect(summary.amount, CashuAmount.sats(1));
      expect(summary.mintUrl.toString(), 'http://localhost:3338');
      expect(summary.memo, 'Thank you');
    });

    test('rejects invalid input without echoing the token', () {
      const codec = CdkTokenCodec();
      const secretInput = 'cashuB-sensitive-secret-value';

      Object? error;
      try {
        codec.decodeToken(secretInput);
      } catch (caught) {
        error = caught;
      }

      expect(error, isA<CashuProtocolException>());
      expect(error.toString(), isNot(contains(secretInput)));
    });

    test('rejects HTTP Mint URLs unless development mode is explicit', () {
      const codec = CdkTokenCodec();

      expect(
        () => codec.decodeToken(officialNut00V4Token),
        throwsA(
          isA<CashuProtocolException>().having(
            (error) => error.code,
            'code',
            'invalid_mint_url',
          ),
        ),
      );
    });
  });

  group('CdkMintInfoMapper', () {
    test('maps sat BOLT11 and optional NUT capabilities', () {
      final snapshot = CdkMintInfoMapper.toSnapshot(
        mintUrl: CashuMintUrl.parse('https://mint.example.com'),
        info: _mintInfo(
          mintDisabled: false,
          meltDisabled: false,
          nut07: true,
          nut08: true,
          nut09: true,
          nut12: true,
        ),
      );

      expect(snapshot.supportsSat, isTrue);
      expect(snapshot.supportsBolt11Mint, isTrue);
      expect(snapshot.supportsBolt11Melt, isTrue);
      expect(
        snapshot.supportedNuts,
        containsAll([
          CashuNut.nut04,
          CashuNut.nut05,
          CashuNut.nut07,
          CashuNut.nut08,
          CashuNut.nut09,
          CashuNut.nut12,
          CashuNut.nut23,
        ]),
      );
      expect(snapshot.version, 'cdk-test/1.0');
    });

    test('does not advertise disabled Mint and Melt methods', () {
      final snapshot = CdkMintInfoMapper.toSnapshot(
        mintUrl: CashuMintUrl.parse('https://mint.example.com'),
        info: _mintInfo(mintDisabled: true, meltDisabled: true),
      );

      expect(snapshot.supportsBolt11Mint, isFalse);
      expect(snapshot.supportsBolt11Melt, isFalse);
      expect(snapshot.supportedNuts, isNot(contains(CashuNut.nut04)));
      expect(snapshot.supportedNuts, isNot(contains(CashuNut.nut05)));
      expect(snapshot.supportedNuts, isNot(contains(CashuNut.nut23)));
    });
  });
}

cdk.MintInfo _mintInfo({
  required bool mintDisabled,
  required bool meltDisabled,
  bool nut07 = false,
  bool nut08 = false,
  bool nut09 = false,
  bool nut12 = false,
}) {
  return cdk.MintInfo(
    name: 'Test Mint',
    pubkey: null,
    version: cdk.MintVersion(name: 'cdk-test', version: '1.0'),
    description: null,
    descriptionLong: null,
    contact: null,
    nuts: cdk.Nuts(
      nut04: cdk.Nut04Settings(
        methods: [
          cdk.MintMethodSettings(
            method: cdk.Bolt11PaymentMethod(),
            unit: cdk.SatCurrencyUnit(),
            minAmount: null,
            maxAmount: null,
            description: true,
          ),
        ],
        disabled: mintDisabled,
      ),
      nut05: cdk.Nut05Settings(
        methods: [
          cdk.MeltMethodSettings(
            method: cdk.Bolt11PaymentMethod(),
            unit: cdk.SatCurrencyUnit(),
            minAmount: null,
            maxAmount: null,
            amountless: false,
          ),
        ],
        disabled: meltDisabled,
      ),
      nut07Supported: nut07,
      nut08Supported: nut08,
      nut09Supported: nut09,
      nut10Supported: false,
      nut11Supported: false,
      nut12Supported: nut12,
      nut14Supported: false,
      nut20Supported: false,
      nut21: null,
      nut22: null,
      nut29: cdk.Nut29Settings(maxBatchSize: null, methods: null),
      mintUnits: [cdk.SatCurrencyUnit()],
      meltUnits: [cdk.SatCurrencyUnit()],
    ),
    iconUrl: null,
    urls: null,
    motd: null,
    time: null,
    tosUrl: null,
  );
}
