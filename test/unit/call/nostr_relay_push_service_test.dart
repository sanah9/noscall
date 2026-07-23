import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call/nostr_relay_push_service.dart';
import 'package:noscall/call/push_token_service.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/account/model/relay_db_isar.dart';
import 'package:noscall/core/account/model/user_db_isar.dart';
import 'package:noscall/core/call/nip_ac_protocol.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeRelayInfoProvider implements NostrRelayPushRelayInfoProvider {
  FakeRelayInfoProvider(this.supportedNipsByRelay);

  final Map<String, String> supportedNipsByRelay;

  @override
  Future<RelayDBISAR?> getRelayDetails(String relay) async {
    return RelayDBISAR(
      url: NostrRelayPushService.normalizeRelayUrl(relay),
      supportedNips: supportedNipsByRelay[relay] ??
          supportedNipsByRelay[
              NostrRelayPushService.normalizeRelayUrl(relay)] ??
          '',
    );
  }
}

class RecordingRelayPushSender implements NostrRelayPushEventSender {
  RecordingRelayPushSender({this.rejectRelays = const <String>{}});

  final Set<String> rejectRelays;
  final List<({Event event, String relay})> sent = [];

  @override
  Future<OKEvent> send(Event event, String relay) async {
    sent.add((event: event, relay: relay));
    if (rejectRelays.contains(relay)) {
      return OKEvent(event.id, false, 'rejected');
    }
    return OKEvent(event.id, true, '');
  }
}

class FakePushTokenApiClient implements PushTokenApiClient {
  @override
  Future<PushTokenRegistration?> registerDevice(
    PushTokenRegistrationRequest request,
  ) async {
    return const PushTokenRegistration(
      deviceRegistrationId: 'device-1',
      callbackUrl: 'https://push.example.com/callback/device-1',
    );
  }

  @override
  Future<bool> unregisterDevice(String deviceRegistrationId) async => true;
}

void main() {
  const privkey =
      '0000000000000000000000000000000000000000000000000000000000000001';
  const pubkey =
      '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PushTokenService.setTestOverrides(apiClient: FakePushTokenApiClient());
    NostrRelayPushService.clearTestOverrides();
    final account = Account.sharedInstance;
    account.me = UserDBISAR(pubKey: pubkey);
    account.currentPubkey = pubkey;
    account.currentPrivkey = privkey;
  });

  tearDown(() {
    PushTokenService.clearTestOverrides();
    NostrRelayPushService.clearTestOverrides();
    final account = Account.sharedInstance;
    account.me = null;
    account.currentPubkey = '';
    account.currentPrivkey = '';
  });

  group('RelayDBISAR.supportsNip9a', () {
    test('parses supported_nips strings robustly', () {
      expect(RelayDBISAR(supportedNips: '[1, 9a, 65]').supportsNip9a, isTrue);
      expect(RelayDBISAR(supportedNips: '1,9A,65').supportsNip9a, isTrue);
      expect(RelayDBISAR(supportedNips: '[1, 9, 65]').supportsNip9a, isFalse);
      expect(RelayDBISAR(supportedNips: '').supportsNip9a, isFalse);
    });
  });

  group('NostrRelayPushService', () {
    test('builds kind 30390 event with include_event and offer filter',
        () async {
      final event = await NostrRelayPushService.buildSubscriptionEvent(
        pubkey: pubkey,
        privkey: privkey,
        relay: 'wss://relay.example.com/',
        callbackUrl: 'https://push.example.com/callback/device-1',
        d: 'sub-1',
      );

      expect(event.kind, NostrRelayPushService.subscriptionKind);
      expect(_firstTagValue(event.tags, 'd'), 'sub-1');
      expect(_firstTagValue(event.tags, 'relay'), 'wss://relay.example.com');
      expect(
        event.tags.any((tag) => tag.length == 1 && tag[0] == 'include_event'),
        isTrue,
      );

      final filter = jsonDecode(_firstTagValue(event.tags, 'filter')!)
          as Map<String, dynamic>;
      expect(filter['kinds'], [NipAcProtocol.wrapKind]);
      expect(filter['#p'], [pubkey]);
      expect(filter['#k'], [NipAcKind.offer.value.toString()]);
    });

    test('sync sends one subscription only to NIP-9a supporting relays',
        () async {
      Account.sharedInstance.me!.relayList = [
        'wss://supported.example.com',
        'wss://unsupported.example.com',
      ];
      await PushTokenService().uploadToken(
        token: 'token-1',
        tokenType: 'apns_voip',
        platform: 'ios',
        pubkey: pubkey,
      );

      final sender = RecordingRelayPushSender();
      NostrRelayPushService.setTestOverrides(
        relayInfoProvider: FakeRelayInfoProvider({
          'wss://supported.example.com': '[1, 9a]',
          'wss://unsupported.example.com': '[1, 65]',
        }),
        eventSender: sender,
      );

      await NostrRelayPushService().sync(force: true);

      final subscriptionEvents =
          sender.sent.where((item) => item.event.kind == 30390).toList();
      expect(subscriptionEvents, hasLength(1));
      expect(subscriptionEvents.single.relay, 'wss://supported.example.com');
      expect(_firstTagValue(subscriptionEvents.single.event.tags, 'callback'),
          'https://push.example.com/callback/device-1');
    });

    test('sync continues when one supporting relay rejects the subscription',
        () async {
      Account.sharedInstance.me!.relayList = [
        'wss://reject.example.com',
        'wss://ok.example.com',
      ];
      await PushTokenService().uploadToken(
        token: 'token-2',
        tokenType: 'apns_voip',
        platform: 'ios',
        pubkey: pubkey,
      );

      final sender =
          RecordingRelayPushSender(rejectRelays: {'wss://reject.example.com'});
      NostrRelayPushService.setTestOverrides(
        relayInfoProvider: FakeRelayInfoProvider({
          'wss://reject.example.com': '[9a]',
          'wss://ok.example.com': '[9a]',
        }),
        eventSender: sender,
      );

      await NostrRelayPushService().sync(force: true);

      final subscriptionRelays = sender.sent
          .where((item) => item.event.kind == 30390)
          .map((item) => item.relay)
          .toSet();
      expect(subscriptionRelays, {
        'wss://reject.example.com',
        'wss://ok.example.com',
      });
    });
  });
}

String? _firstTagValue(List<List<String>> tags, String name) {
  for (final tag in tags) {
    if (tag.length >= 2 && tag[0] == name) return tag[1];
  }
  return null;
}
