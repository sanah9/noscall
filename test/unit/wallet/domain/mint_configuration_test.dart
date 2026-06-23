import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';
import 'package:noscall/wallet/domain/mint_configuration.dart';

void main() {
  group('DefaultMintProvider', () {
    test('production default provider contains no Mint', () async {
      const provider = EmptyDefaultMintProvider();

      expect(await provider.load(), isEmpty);
    });

    test('configured provider can be added without hard-coded URLs', () async {
      final mint = CashuMintUrl.parse('https://mint.example.com');
      final suggestion = DefaultMintSuggestion(
        url: mint,
        displayName: 'Configured Mint',
      );
      final provider = ConfiguredDefaultMintProvider([suggestion, suggestion]);

      expect(await provider.load(), [suggestion]);
    });
  });

  group('MintCapabilityPolicy', () {
    const policy = MintCapabilityPolicy();

    test('enables Cashu and BOLT11 for a complete sat Mint', () {
      final decision = policy.evaluate(_snapshot());

      expect(decision.canUseCashu, isTrue);
      expect(decision.canMintBolt11, isTrue);
      expect(decision.canMeltBolt11, isTrue);
      expect(decision.missingCoreNuts, isEmpty);
    });

    test('rejects core use when recovery support is missing', () {
      final decision = policy.evaluate(
        _snapshot(supportedNuts: _allNuts..remove(CashuNut.nut09)),
      );

      expect(decision.canUseCashu, isFalse);
      expect(decision.missingCoreNuts, {CashuNut.nut09});
      expect(decision.canMintBolt11, isFalse);
      expect(decision.canMeltBolt11, isFalse);
    });

    test('disables only Melt when NUT-08 is unavailable', () {
      final decision = policy.evaluate(
        _snapshot(supportedNuts: _allNuts..remove(CashuNut.nut08)),
      );

      expect(decision.canUseCashu, isTrue);
      expect(decision.canMintBolt11, isTrue);
      expect(decision.canMeltBolt11, isFalse);
    });

    test('does not accept a non-sat Mint', () {
      final decision = policy.evaluate(_snapshot(supportsSat: false));

      expect(decision.canUseCashu, isFalse);
      expect(decision.canMintBolt11, isFalse);
      expect(decision.canMeltBolt11, isFalse);
    });
  });
}

Set<CashuNut> get _allNuts => {
  CashuNut.nut00,
  CashuNut.nut01,
  CashuNut.nut02,
  CashuNut.nut03,
  CashuNut.nut04,
  CashuNut.nut05,
  CashuNut.nut06,
  CashuNut.nut07,
  CashuNut.nut08,
  CashuNut.nut09,
  CashuNut.nut12,
  CashuNut.nut23,
};

CashuMintSnapshot _snapshot({
  Set<CashuNut>? supportedNuts,
  bool supportsSat = true,
}) {
  return CashuMintSnapshot(
    url: CashuMintUrl.parse('https://mint.example.com'),
    supportedNuts: supportedNuts ?? _allNuts,
    supportsSat: supportsSat,
    supportsBolt11Mint: true,
    supportsBolt11Melt: true,
  );
}
