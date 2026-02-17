import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/core/account/account.dart';
import '../../../helpers/test_data.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('Account', () {
    late Account account;

    setUp(() {
      account = Account.sharedInstance;
    });

    tearDown(() {
      // Clean up test data
      account.me = null;
      account.currentPubkey = '';
      account.currentPrivkey = '';
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
      test('should not throw when me is set (persists to DB; DB not mocked)', () async {
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
      });

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
        expect(account.userCache[testUser.pubKey]?.value.pubKey, equals(testUser.pubKey));
      });
    });
  });
}
