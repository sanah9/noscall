import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/account/account_relay.dart';
import 'package:noscall/core/account/account_dependencies.dart';
import 'package:noscall/core/account/account_relay_dependencies.dart';
import 'package:noscall/core/account/model/user_db_isar.dart';
import 'package:noscall/core/common/network/connect.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../helpers/test_data.dart';
import '../../../helpers/test_helpers.dart';

class FakeAccountPersistence implements AccountPersistence {
  final Map<String, UserDBISAR> users = {};
  final List<UserDBISAR> savedUsers = [];

  @override
  Future<void> close() async {}

  @override
  Future<UserDBISAR?> findUserByPubkey(String pubkey) async => users[pubkey];

  @override
  Future<List<UserDBISAR>> loadAllUsers() async => users.values.toList();

  @override
  Future<void> saveUser(UserDBISAR user) async {
    users[user.pubKey] = user;
    savedUsers.add(user);
  }
}

class FakeAccountRelayRuntime implements AccountRelayRuntime {
  final List<String> connectedRelays = [];
  final List<String> closedRelays = [];
  final List<Event> sentEvents = [];
  int connectGeneralRelaysCalls = 0;
  int connectDMRelaysCalls = 0;
  int connectInboxOutboxRelaysCalls = 0;
  int closeAllRelaysCalls = 0;
  int resumeAllRelaysCalls = 0;

  @override
  void closeRelay(String relay, RelayKind relayKind) {
    closedRelays.add('$relay|${relayKind.name}');
  }

  @override
  Future<void> closeAllRelays() async {
    closeAllRelaysCalls += 1;
  }

  @override
  void connectDMRelays() {
    connectDMRelaysCalls += 1;
  }

  @override
  void connectGeneralRelays() {
    connectGeneralRelaysCalls += 1;
  }

  @override
  void connectInboxOutboxRelays() {
    connectInboxOutboxRelaysCalls += 1;
  }

  @override
  void connectRelay(String relay, RelayKind relayKind) {
    connectedRelays.add('$relay|${relayKind.name}');
  }

  @override
  Future<void> resumeAllRelays() async {
    resumeAllRelaysCalls += 1;
  }

  @override
  Future<OKEvent> sendEvent(Event event) async {
    sentEvents.add(event);
    return OKEvent(event.id, true, '');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Account Relay Management', () {
    late Account account;
    late FakeAccountPersistence persistence;
    late FakeAccountRelayRuntime relayRuntime;
    late Keychain keychain;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      account = Account.sharedInstance;
      persistence = FakeAccountPersistence();
      relayRuntime = FakeAccountRelayRuntime();
      keychain = Keychain.generate();
      Account.setTestDependencies(persistence: persistence);
      setAccountRelayRuntimeForTest(relayRuntime);

      account.me = TestHelpers.createTestUser(pubKey: keychain.public);
      account.currentPubkey = keychain.public;
      account.currentPrivkey = keychain.private;
      account.me!.relayList = [];
      account.me!.dmRelayList = [];
      account.me!.inboxRelayList = [];
      account.me!.outboxRelayList = [];
    });

    tearDown(() {
      account.me?.relayList = [];
      account.me?.dmRelayList = [];
      account.me?.inboxRelayList = [];
      account.me?.outboxRelayList = [];
      account.currentPubkey = '';
      account.currentPrivkey = '';
      Account.clearTestDependencies();
      clearAccountRelayRuntimeForTest();
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
        expect(relayRuntime.connectedRelays, ['$testRelay|general']);
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
        expect(relayRuntime.closedRelays, ['$testRelay|general']);
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
        expect(relayRuntime.connectGeneralRelaysCalls, 1);
        expect(persistence.savedUsers, isNotEmpty);
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

    group('DM relay management', () {
      test(
        'setDMRelayListToRelay updates list and sends encoded event',
        () async {
          final relays = [TestData.validRelayUrl];

          final result = await account.setDMRelayListToRelay(relays);

          expect(result.status, isTrue);
          expect(account.me?.dmRelayList, relays);
          expect(account.me?.lastDMRelayListUpdatedTime, greaterThan(0));
          expect(relayRuntime.connectDMRelaysCalls, 1);
          expect(relayRuntime.sentEvents, hasLength(1));
          expect(relayRuntime.sentEvents.single.pubkey, account.currentPubkey);
        },
      );

      test('addDMRelay connects relay and updates the DM list', () async {
        const relay = TestData.validRelayUrl;

        final result = await account.addDMRelay(relay);

        expect(result.status, isTrue);
        expect(account.me?.dmRelayList, contains(relay));
        expect(relayRuntime.connectedRelays, ['$relay|dm']);
      });

      test('removeDMRelay closes relay and updates the DM list', () async {
        const relay = TestData.validRelayUrl;
        account.me!.dmRelayList = [relay];

        final result = await account.removeDMRelay(relay);

        expect(result.status, isTrue);
        expect(account.me?.dmRelayList, isNot(contains(relay)));
        expect(relayRuntime.closedRelays, ['$relay|dm']);
      });
    });

    group('Inbox and Outbox relay management', () {
      test('addInboxRelay wires inbox runtime kind', () async {
        const relay = TestData.validRelayUrl;

        final result = await account.addInboxRelay(relay);

        expect(result.status, isTrue);
        expect(account.me?.inboxRelayList, contains(relay));
        expect(relayRuntime.connectedRelays, ['$relay|inbox']);
        expect(relayRuntime.connectInboxOutboxRelaysCalls, 1);
        expect(relayRuntime.sentEvents, hasLength(1));
      });

      test('addOutboxRelay wires outbox runtime kind', () async {
        const relay = TestData.validRelayUrl;

        final result = await account.addOutboxRelay(relay);

        expect(result.status, isTrue);
        expect(account.me?.outboxRelayList, contains(relay));
        expect(relayRuntime.connectedRelays, ['$relay|outbox']);
        expect(relayRuntime.connectInboxOutboxRelaysCalls, 1);
        expect(relayRuntime.sentEvents, hasLength(1));
      });

      test(
        'removeInboxRelay closes inbox relay and resends relay list',
        () async {
          const relay = TestData.validRelayUrl;
          account.me!.inboxRelayList = [relay];

          final result = await account.removeInboxRelay(relay);

          expect(result.status, isTrue);
          expect(account.me?.inboxRelayList, isEmpty);
          expect(relayRuntime.closedRelays, ['$relay|inbox']);
          expect(relayRuntime.sentEvents, hasLength(1));
        },
      );
    });

    group('Runtime passthrough', () {
      test('closeAllRelays delegates to runtime', () async {
        await account.closeAllRelays();

        expect(relayRuntime.closeAllRelaysCalls, 1);
      });

      test('resumeAllRelays delegates to runtime', () async {
        await account.resumeAllRelays();

        expect(relayRuntime.resumeAllRelaysCalls, 1);
      });
    });
  });
}
