import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/auth/auth_service.dart';
import 'package:noscall/auth/auth_service_dependencies.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import 'package:noscall/core/common/config/call_core_init_config.dart';

class FakeAuthPreferencesStore implements AuthPreferencesStore {
  final Map<String, String> values = {};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}

class FakeAuthAccountGateway implements AuthAccountGateway {
  UserDBISAR? nextUser;
  bool initCalled = false;
  bool logoutCalled = false;
  String publicKeyFromPrivateKey =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
  String bunkerPubkey =
      'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789';
  UserDBISAR? _currentUser;
  String _currentPubkey = '';

  @override
  UserDBISAR? get currentUser => _currentUser;

  @override
  String get currentPubkey => _currentPubkey;

  @override
  String getPublicKey(String privkey) => publicKeyFromPrivateKey;

  @override
  Future<String> getPublicKeyWithNIP46URI(String uri) async => bunkerPubkey;

  @override
  Future<void> initAccount() async {
    initCalled = true;
  }

  @override
  Future<UserDBISAR?> loginWithNip46URI(String uri) async {
    _currentUser = nextUser;
    _currentPubkey = nextUser?.pubKey ?? '';
    return nextUser;
  }

  @override
  Future<UserDBISAR?> loginWithPriKey(String privkey) async {
    _currentUser = nextUser;
    _currentPubkey = nextUser?.pubKey ?? '';
    return nextUser;
  }

  @override
  Future<UserDBISAR?> loginWithPubKey(
      String pubkey, SignerApplication signerApplication) async {
    _currentUser = nextUser;
    _currentPubkey = nextUser?.pubKey ?? pubkey;
    return nextUser;
  }

  @override
  Future<UserDBISAR?> loginWithPubKeyAndPassword(String pubkey) async {
    _currentUser = nextUser;
    _currentPubkey = nextUser?.pubKey ?? pubkey;
    return nextUser;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    _currentUser = null;
    _currentPubkey = '';
  }
}

class FakeAuthDatabaseGateway implements AuthDatabaseGateway {
  final List<String> openedPubkeys = [];

  @override
  Future<void> open(String pubkey) async {
    openedPubkeys.add(pubkey);
  }
}

class FakeAuthRuntimeGateway implements AuthRuntimeGateway {
  String documentsPath = '/tmp';
  ChatCoreInitConfig? lastConfig;
  bool initRtcCalled = false;
  bool clearPushTokensCalled = false;

  @override
  Future<void> clearPushTokens() async {
    clearPushTokensCalled = true;
  }

  @override
  Future<String> getApplicationDocumentsPath() async => documentsPath;

  @override
  Future<void> initChatCore(ChatCoreInitConfig config) async {
    lastConfig = config;
  }

  @override
  Future<void> initRtc() async {
    initRtcCalled = true;
  }
}

class FakeAuthPlatformGateway implements AuthPlatformGateway {
  FakeAuthPlatformGateway({
    this.isAndroid = false,
    this.amberInstalled = false,
    this.amberPubkey,
  });

  @override
  final bool isAndroid;
  final bool amberInstalled;
  final String? amberPubkey;

  @override
  Future<String?> getAmberPublicKey() async => amberPubkey;

  @override
  Future<bool> isAmberInstalled() async => amberInstalled;
}

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
    late FakeAuthPreferencesStore preferences;
    late FakeAuthAccountGateway accountGateway;
    late FakeAuthDatabaseGateway databaseGateway;
    late FakeAuthRuntimeGateway runtimeGateway;
    late FakeAuthPlatformGateway platformGateway;

    setUp(() {
      preferences = FakeAuthPreferencesStore();
      accountGateway = FakeAuthAccountGateway();
      databaseGateway = FakeAuthDatabaseGateway();
      runtimeGateway = FakeAuthRuntimeGateway();
      platformGateway = FakeAuthPlatformGateway();
      AuthService.setTestDependencies(
        AuthServiceDependencies(
          preferences: preferences,
          account: accountGateway,
          database: databaseGateway,
          runtime: runtimeGateway,
          platform: platformGateway,
        ),
      );
      authService = AuthService();
      authService.resetForTest();
    });

    tearDown(() {
      authService.resetForTest();
      AuthService.clearTestDependencies();
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

      test('returns false for invalid nsec prefix (nsec with bad payload)',
          () async {
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

    group('dependency injection', () {
      test('initialize uses injected dependencies for auto login', () async {
        const pubkey =
            '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
        preferences.values['noscall_user_pubkey'] = pubkey;
        preferences.values['noscall_login_method'] = 'privateKey';
        accountGateway.nextUser = UserDBISAR(pubKey: pubkey);

        await authService.initialize();

        expect(databaseGateway.openedPubkeys, [pubkey]);
        expect(accountGateway.initCalled, isTrue);
        expect(runtimeGateway.lastConfig?.pubkey, pubkey);
        expect(runtimeGateway.initRtcCalled, isTrue);
        expect(authService.isAuthenticated, isTrue);
        expect(authService.getUserInfo()['pubkey'], pubkey);
      });

      test('logout clears injected preferences and runtime state', () async {
        const pubkey =
            '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
        preferences.values['noscall_user_pubkey'] = pubkey;
        preferences.values['noscall_login_method'] = 'privateKey';
        preferences.values['noscall_user_bunker_url'] = 'bunker://relay';
        accountGateway.nextUser = UserDBISAR(pubKey: pubkey);

        await authService.initialize();
        await authService.logout();

        expect(accountGateway.logoutCalled, isTrue);
        expect(runtimeGateway.clearPushTokensCalled, isTrue);
        expect(preferences.values.containsKey('noscall_user_pubkey'), isFalse);
        expect(preferences.values.containsKey('noscall_login_method'), isFalse);
        expect(authService.isAuthenticated, isFalse);
      });
    });
  });
}
