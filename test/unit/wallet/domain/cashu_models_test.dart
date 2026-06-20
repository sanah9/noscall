import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  group('CashuMintUrl', () {
    test('normalizes host casing and trailing slash', () {
      final mintUrl = CashuMintUrl.parse('  https://MINT.EXAMPLE/path///  ');

      expect(mintUrl.toString(), 'https://mint.example/path');
    });

    test('treats normalized URLs as equal', () {
      final first = CashuMintUrl.parse('https://mint.example/');
      final second = CashuMintUrl.parse('https://MINT.EXAMPLE');

      expect(first, second);
    });

    test('rejects insecure HTTP by default', () {
      expect(
        () => CashuMintUrl.parse('http://mint.example'),
        throwsFormatException,
      );
    });

    test('allows insecure HTTP only when explicitly enabled', () {
      final mintUrl = CashuMintUrl.parse(
        'http://127.0.0.1:3338/',
        allowInsecureHttp: true,
      );

      expect(mintUrl.toString(), 'http://127.0.0.1:3338');
    });

    test('rejects credentials, query, and fragment', () {
      expect(
        () => CashuMintUrl.parse('https://user@mint.example'),
        throwsFormatException,
      );
      expect(
        () => CashuMintUrl.parse('https://mint.example?token=value'),
        throwsFormatException,
      );
      expect(
        () => CashuMintUrl.parse('https://mint.example#fragment'),
        throwsFormatException,
      );
    });
  });

  group('CashuAmount', () {
    test('requires positive values for asset operations', () {
      expect(() => CashuAmount.positiveSats(0), throwsArgumentError);
      expect(CashuAmount.positiveSats(21).value, 21);
    });

    test('does not allow subtraction to create a negative amount', () {
      final balance = CashuAmount.sats(10);

      expect(() => balance - CashuAmount.sats(11), throwsStateError);
    });

    test('adds and subtracts integer satoshi amounts exactly', () {
      final first = CashuAmount.sats(10);
      final second = CashuAmount.sats(3);

      expect(first + second, CashuAmount.sats(13));
      expect(first - second, CashuAmount.sats(7));
    });
  });
}
