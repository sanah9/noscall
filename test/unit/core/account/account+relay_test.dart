import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/account/account+relay.dart';
import '../../../helpers/test_data.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  // Initialize Flutter binding because Connect singleton needs to access platform channels
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Account Relay Management', () {
    late Account account;

    setUp(() {
      account = Account.sharedInstance;
      // Initialize test user
      account.me = TestHelpers.createTestUser(
        pubKey: TestData.validPubkey,
      );
      account.me!.relayList = [];
    });

    tearDown(() {
      account.me?.relayList = [];
      account.me?.dmRelayList = [];
      account.me?.inboxRelayList = [];
      account.me?.outboxRelayList = [];
    });

    group('addGeneralRelay', () {
      test('should add relay to list when relay is valid', () async {
        // Arrange
        const testRelay = TestData.validRelayUrl;
        
        // Act
        final result = await account.addGeneralRelay(testRelay);
        
        // Assert
        expect(result.status, isTrue);
        expect(account.me?.relayList, contains(testRelay));
      });

      test('should not add duplicate relay', () async {
        // Arrange
        const testRelay = TestData.validRelayUrl;
        account.me!.relayList = [testRelay];
        
        // Act
        final result = await account.addGeneralRelay(testRelay);
        
        // Assert
        expect(result.status, isFalse);
        expect(result.message, 'already exit');
        expect(account.me!.relayList?.length, equals(1));
      });

      test('should return error when relay is empty', () async {
        // Act
        final result = await account.addGeneralRelay('');
        
        // Assert
        expect(result.status, isFalse);
        expect(result.message, 'empty relay');
      });
    });

    group('removeGeneralRelay', () {
      test('should remove relay from list when relay exists', () async {
        // Arrange
        const testRelay = TestData.validRelayUrl;
        account.me!.relayList = [testRelay];
        
        // Act
        final result = await account.removeGeneralRelay(testRelay);
        
        // Assert
        expect(result.status, isTrue);
        expect(account.me?.relayList, isNot(contains(testRelay)));
      });

      test('should return error when relay does not exist', () async {
        // Arrange
        const testRelay = TestData.validRelayUrl;
        account.me!.relayList = [];
        
        // Act
        final result = await account.removeGeneralRelay(testRelay);
        
        // Assert
        expect(result.status, isFalse);
        expect(result.message, 'not exit');
      });

      test('should return error when relay is empty', () async {
        // Act
        final result = await account.removeGeneralRelay('');
        
        // Assert
        expect(result.status, isFalse);
        expect(result.message, 'empty relay');
      });
    });

    group('setGeneralRelayListToLocal', () {
      test('should update relay list and timestamp', () async {
        // Arrange
        final relays = [
          TestData.validRelayUrl,
          TestHelpers.createValidRelayUrl(host: 'another.relay.com'),
        ];
        
        // Act
        final result = await account.setGeneralRelayListToLocal(relays);
        
        // Assert
        expect(result.status, isTrue);
        expect(account.me?.relayList, equals(relays));
        expect(account.me?.lastRelayListUpdatedTime, greaterThan(0));
      });
    });

    group('getMyGeneralRelayList', () {
      test('should return list of RelayDBISAR objects', () {
        // Arrange
        account.me!.relayList = [
          TestData.validRelayUrl,
          TestHelpers.createValidRelayUrl(host: 'another.relay.com'),
        ];
        
        // Act
        final result = account.getMyGeneralRelayList();
        
        // Assert
        expect(result.length, equals(2));
        expect(result[0].url, equals(TestData.validRelayUrl));
      });

      test('should return empty list when no relays configured', () {
        // Arrange
        account.me!.relayList = [];
        
        // Act
        final result = account.getMyGeneralRelayList();
        
        // Assert
        expect(result, isEmpty);
      });
    });
  });
}
