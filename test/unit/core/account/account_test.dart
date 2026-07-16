import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/account/account_dependencies.dart';
import 'package:noscall/core/account/account_secret_store.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import 'package:noscall/core/common/network/connect.dart';
import '../../../helpers/test_data.dart';
import '../../../helpers/test_helpers.dart';
import '../../../helpers/test_setup.dart';

class FakeAccountPersistence implements AccountPersistence {
  final Map<String, UserDBISAR> users = {};
  bool closeCalled = false;
  UserDBISAR? lastSavedUser;

  @override
  Future<void> close() async {
    closeCalled = true;
  }

  @override
  Future<UserDBISAR?> findUserByPubkey(String pubkey) async {
    return users[pubkey];
  }

  @override
  Future<List<UserDBISAR>> loadAllUsers() async {
    return users.values.toList();
  }

  @override
  Future<void> saveUser(UserDBISAR user) async {
    users[user.pubKey] = user;
    lastSavedUser = user;
  }
}

class FakeAccountSecretStore implements AccountSecretStore {
  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

void main() {
  group('Account', () {
    late Account account;
    late FakeAccountPersistence persistence;
    late FakeAccountSecretStore secretStore;

    setUp(() {
      account = Account.sharedInstance;
      persistence = FakeAccountPersistence();
      secretStore = FakeAccountSecretStore();
      Account.setTestDependencies(
        persistence: persistence,
        secretStore: secretStore,
      );
      Connect.setTestOverrides(
        connectivity: TestSetup.connectivity(),
        socketConnector: TestSetup.socketConnector(),
      );
    });

    tearDown(() async {
      // Clean up test data
      account.me = null;
      account.currentPubkey = '';
      account.currentPrivkey = '';
      await Connect.sharedInstance.closeAllConnects();
      Connect.clearTestOverrides();
      Account.clearTestDependencies();
    });

    group('isValidPubKey', () {
      test('should return true for valid 64-character hex pubkey', () {
        expect(account.isValidPubKey(TestData.validPubkey), isTrue);
      });

      test('should return false for invalid pubkey', () {
        expect(account.isValidPubKey(TestData.invalidPubkey), isFalse);
        expect(account.isValidPubKey(''), isFalse);
        expect(account.isValidPubKey('123'), isFalse);
        // Use List.filled to create repeated strings
        expect(account.isValidPubKey(List.filled(63, 'a').join()), isFalse);
        expect(account.isValidPubKey(List.filled(65, 'a').join()), isFalse);
      });
    });

    group('syncMe', () {
      test(
        'should not throw when me is set (persists to DB; DB not mocked)',
        () async {
          // Arrange
          final testUser = TestHelpers.createTestUser(
            pubKey: TestData.validPubkey,
            name: TestData.testUserName,
          );
          account.me = testUser;

          // Act & Assert: syncMe() calls saveUserToDB(me!). We only verify no throw
          // and me still set; actual DB write is not asserted without mocking DB.
          await account.syncMe();
          expect(account.me, isNotNull);
        },
      );

      test('throws when me is null', () async {
        account.me = null;
        expect(() => account.syncMe(), throwsA(anything));
      });
    });

    group('User Management', () {
      test('should update or create user notifier', () {
        // Arrange
        final testUser = TestHelpers.createTestUser(
          pubKey: TestData.validPubkey,
        );

        // Act
        account.updateOrCreateUserNotifier(testUser.pubKey, testUser);

        // Assert
        expect(account.userCache.containsKey(testUser.pubKey), isTrue);
        expect(
          account.userCache[testUser.pubKey]?.value.pubKey,
          equals(testUser.pubKey),
        );
      });
    });

    group('Persistence injection', () {
      test('getUserFromDB reads from injected persistence', () async {
        final storedUser = TestHelpers.createTestUser(
          pubKey: TestData.validPubkey,
          name: TestData.testUserName,
        );
        persistence.users[storedUser.pubKey] = storedUser;

        final result = await account.getUserFromDB(
          pubkey: TestData.validPubkey,
        );

        expect(result?.pubKey, TestData.validPubkey);
        expect(
          account.userCache[TestData.validPubkey]?.value.name,
          TestData.testUserName,
        );
      });

      test('saveUserToDB writes through injected persistence', () async {
        final user = TestHelpers.createTestUser(pubKey: TestData.validPubkey);

        await Account.saveUserToDB(user);

        expect(persistence.lastSavedUser?.pubKey, TestData.validPubkey);
      });

      test(
        'loginWithPriKey stores decrypt password outside UserDBISAR',
        () async {
          final keychain = Keychain.generate();

          final result = await account.loginWithPriKey(keychain.private);

          final secretKey = AccountSecretKeys.privateKeyPassword(
            keychain.public,
          );
          expect(result?.pubKey, keychain.public);
          expect(secretStore.values[secretKey], isNotNull);
          expect(persistence.lastSavedUser?.encryptedPrivKey, isNotEmpty);
          expect(persistence.lastSavedUser?.defaultPassword, isEmpty);
        },
      );

      test(
        'loginWithPubKeyAndPassword migrates legacy defaultPassword',
        () async {
          final keychain = Keychain.generate();
          const legacyPassword = 'legacy-password';
          final encryptedPrivKey = encryptPrivateKey(
            hexToBytes(keychain.private),
            legacyPassword,
          );
          final storedUser = UserDBISAR(
            pubKey: keychain.public,
            encryptedPrivKey: bytesToHex(encryptedPrivKey),
            defaultPassword: legacyPassword,
          );
          persistence.users[storedUser.pubKey] = storedUser;

          final result = await account.loginWithPubKeyAndPassword(
            keychain.public,
          );

          final secretKey = AccountSecretKeys.privateKeyPassword(
            keychain.public,
          );
          expect(result?.pubKey, keychain.public);
          expect(secretStore.values[secretKey], legacyPassword);
          expect(persistence.lastSavedUser?.defaultPassword, isEmpty);
          expect(account.currentPrivkey, keychain.private);
        },
      );
    });

    group('init', () {
      test('does not start runtime without an authenticated session', () async {
        account.me = null;
        account.currentPubkey = '';
        account.currentPrivkey = '';

        await account.init();

        expect(account.hasAuthenticatedSession, isFalse);
        expect(account.isSessionInitialized, isFalse);
        expect(account.timer, isNull);
        expect(Connect.sharedInstance.isInitialized, isFalse);
      });
    });
  });
}
