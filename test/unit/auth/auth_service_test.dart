import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/auth/auth_service.dart';

void main() {
  group('LoginMethod', () {
    group('fromString', () {
      test('returns privateKey for "privateKey"', () {
        expect(LoginMethod.fromString('privateKey'), LoginMethod.privateKey);
      });

      test('returns amber for "amber"', () {
        expect(LoginMethod.fromString('amber'), LoginMethod.amber);
      });

      test('returns bunker for "bunker"', () {
        expect(LoginMethod.fromString('bunker'), LoginMethod.bunker);
      });

      test('throws ArgumentError for unknown value', () {
        expect(
          () => LoginMethod.fromString('unknown'),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Unknown login method'),
          )),
        );
      });

      test('throws ArgumentError for empty string', () {
        expect(
          () => LoginMethod.fromString(''),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('value', () {
      test('privateKey has value "privateKey"', () {
        expect(LoginMethod.privateKey.value, 'privateKey');
      });

      test('amber has value "amber"', () {
        expect(LoginMethod.amber.value, 'amber');
      });

      test('bunker has value "bunker"', () {
        expect(LoginMethod.bunker.value, 'bunker');
      });
    });

    group('getSignerApplication', () {
      test('privateKey returns SignerApplication.none', () {
        expect(
          LoginMethod.privateKey.getSignerApplication(),
          SignerApplication.none,
        );
      });

      test('amber returns SignerApplication.androidSigner', () {
        expect(
          LoginMethod.amber.getSignerApplication(),
          SignerApplication.androidSigner,
        );
      });

      test('bunker returns SignerApplication.remoteSigner', () {
        expect(
          LoginMethod.bunker.getSignerApplication(),
          SignerApplication.remoteSigner,
        );
      });
    });
  });

  group('AuthService', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    group('generatePrivateKey', () {
      test('returns a 64-character string', () {
        final key = authService.generatePrivateKey();
        expect(key.length, 64);
      });

      test('returns only hexadecimal characters', () {
        final key = authService.generatePrivateKey();
        expect(RegExp(r'^[a-fA-F0-9]+$').hasMatch(key), isTrue);
      });

      test('returns different keys on multiple calls', () {
        final key1 = authService.generatePrivateKey();
        final key2 = authService.generatePrivateKey();
        expect(key1, isNot(equals(key2)));
      });
    });

    group('getUserInfo', () {
      test('returns map with keys pubkey, npub, loginMethod', () {
        final info = authService.getUserInfo();
        expect(info.containsKey('pubkey'), isTrue);
        expect(info.containsKey('npub'), isTrue);
        expect(info.containsKey('loginMethod'), isTrue);
      });

      test('returns string values for all keys', () {
        final info = authService.getUserInfo();
        expect(info['pubkey'], isA<String>());
        expect(info['npub'], isA<String>());
        expect(info['loginMethod'], isA<String>());
      });

      test('returns empty strings when not logged in', () {
        final info = authService.getUserInfo();
        expect(info['pubkey'], '');
        expect(info['npub'], '');
        expect(info['loginMethod'], '');
      });
    });

    group('loginWithPrivateKey', () {
      test('returns false for empty string', () async {
        final result = await authService.loginWithPrivateKey('');
        expect(result, isFalse);
      });

      test('returns false for key shorter than 64 characters', () async {
        final result = await authService.loginWithPrivateKey(
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcde',
        );
        expect(result, isFalse);
      });

      test('returns false for key longer than 64 characters', () async {
        final result = await authService.loginWithPrivateKey(
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0',
        );
        expect(result, isFalse);
      });

      test('returns false for 64 characters that are not valid hex', () async {
        final result = await authService.loginWithPrivateKey(
          'g' * 64,
        );
        expect(result, isFalse);
      });

      test('returns false for invalid nsec prefix (nsec with bad payload)', () async {
        final result = await authService.loginWithPrivateKey('nsec1invalid');
        expect(result, isFalse);
      });

      test('returns false for nsec prefix but too short', () async {
        final result = await authService.loginWithPrivateKey('nsec1');
        expect(result, isFalse);
      });
    });

    group('loginWithBunkerUrl', () {
      test('returns false for empty string', () async {
        final result = await authService.loginWithBunkerUrl('');
        expect(result, isFalse);
      });

      test('returns false for whitespace-only string', () async {
        final result = await authService.loginWithBunkerUrl('   ');
        expect(result, isFalse);
      });
    });

    group('authStateStream', () {
      test('exposes a Stream<bool>', () {
        expect(authService.authStateStream, isNotNull);
        expect(authService.authStateStream, isA<Stream<bool>>());
      });
    });
  });
}
