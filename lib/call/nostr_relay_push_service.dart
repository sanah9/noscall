import 'dart:async';
import 'dart:convert';

import 'package:nostr_core_dart/nostr.dart';

import 'package:noscall/call/push_token_service.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/account/model/relay_db_isar.dart';
import 'package:noscall/core/account/relays.dart';
import 'package:noscall/core/call/nip_ac_protocol.dart';
import 'package:noscall/core/common/network/connect.dart';
import 'package:noscall/core/common/storage/preferences_store.dart';
import 'package:noscall/core/common/utils/log_utils.dart';

class RelayPushSubscriptionRecord {
  const RelayPushSubscriptionRecord({
    required this.relay,
    required this.d,
    required this.eventId,
    required this.callbackUrl,
    required this.createdAt,
  });

  final String relay;
  final String d;
  final String eventId;
  final String callbackUrl;
  final int createdAt;

  Map<String, dynamic> toJson() => {
        'relay': relay,
        'd': d,
        'eventId': eventId,
        'callbackUrl': callbackUrl,
        'createdAt': createdAt,
      };

  static RelayPushSubscriptionRecord? fromJson(Map<String, dynamic> json) {
    final relay = json['relay']?.toString() ?? '';
    final d = json['d']?.toString() ?? '';
    final eventId = json['eventId']?.toString() ?? '';
    final callbackUrl = json['callbackUrl']?.toString() ?? '';
    final createdAt = json['createdAt'];
    if (relay.isEmpty || d.isEmpty || callbackUrl.isEmpty) return null;
    return RelayPushSubscriptionRecord(
      relay: relay,
      d: d,
      eventId: eventId,
      callbackUrl: callbackUrl,
      createdAt: createdAt is int ? createdAt : 0,
    );
  }
}

abstract interface class NostrRelayPushRelayInfoProvider {
  Future<RelayDBISAR?> getRelayDetails(String relay);
}

class DefaultNostrRelayPushRelayInfoProvider
    implements NostrRelayPushRelayInfoProvider {
  const DefaultNostrRelayPushRelayInfoProvider();

  @override
  Future<RelayDBISAR?> getRelayDetails(String relay) {
    return Relays.getRelayDetails(relay);
  }
}

abstract interface class NostrRelayPushEventSender {
  Future<OKEvent> send(Event event, String relay);
}

class DefaultNostrRelayPushEventSender implements NostrRelayPushEventSender {
  const DefaultNostrRelayPushEventSender();

  @override
  Future<OKEvent> send(Event event, String relay) async {
    final completer = Completer<OKEvent>();
    Timer? timeout;
    try {
      await Connect.sharedInstance
          .connectRelays([relay], relayKind: RelayKind.notification);
      timeout = Timer(const Duration(seconds: Connect.timeout + 2), () {
        if (!completer.isCompleted) {
          completer.complete(OKEvent(event.id, false, 'Time Out'));
        }
      });
      Connect.sharedInstance.sendEvent(
        event,
        toRelays: [relay],
        relayKinds: const [RelayKind.notification],
        sendCallBack: (ok, _) {
          if (!completer.isCompleted) {
            completer.complete(OKEvent(event.id, ok.status, ok.message));
          }
        },
      );
      return await completer.future;
    } catch (e) {
      return OKEvent(event.id, false, e.toString());
    } finally {
      timeout?.cancel();
    }
  }
}

class NostrRelayPushService {
  NostrRelayPushService._internal();
  factory NostrRelayPushService() => sharedInstance;
  static final NostrRelayPushService sharedInstance =
      NostrRelayPushService._internal();

  static const int subscriptionKind = 30390;
  static const int deletionKind = 5;
  static const String _subscriptionsKeyPrefix =
      'noscall_nostr_relay_push_subscriptions';
  static const String _lastSyncKeyPrefix = 'noscall_nostr_relay_push_last_sync';
  static const String _notificationsEnabledKey =
      'noscall_notifications_enabled';
  static const Duration resyncInterval = Duration(hours: 24);

  static NostrRelayPushRelayInfoProvider _relayInfoProvider =
      const DefaultNostrRelayPushRelayInfoProvider();
  static NostrRelayPushEventSender _eventSender =
      const DefaultNostrRelayPushEventSender();

  final PreferencesStore _prefs = PreferencesStore.shared;
  Future<void>? _syncFuture;

  static void setTestOverrides({
    NostrRelayPushRelayInfoProvider? relayInfoProvider,
    NostrRelayPushEventSender? eventSender,
  }) {
    _relayInfoProvider =
        relayInfoProvider ?? const DefaultNostrRelayPushRelayInfoProvider();
    _eventSender = eventSender ?? const DefaultNostrRelayPushEventSender();
  }

  static void clearTestOverrides() {
    _relayInfoProvider = const DefaultNostrRelayPushRelayInfoProvider();
    _eventSender = const DefaultNostrRelayPushEventSender();
  }

  static String normalizeRelayUrl(String relay) {
    var normalized = relay.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  static Future<Event> buildSubscriptionEvent({
    required String pubkey,
    required String privkey,
    required String relay,
    required String callbackUrl,
    required String d,
  }) {
    final normalizedRelay = normalizeRelayUrl(relay);
    final filter = jsonEncode({
      'kinds': [NipAcProtocol.wrapKind],
      '#p': [pubkey],
      '#k': [NipAcKind.offer.value.toString()],
    });
    return Event.from(
      kind: subscriptionKind,
      tags: [
        ['d', d],
        ['relay', normalizedRelay],
        ['filter', filter],
        ['callback', callbackUrl],
        ['include_event'],
      ],
      content: '',
      pubkey: pubkey,
      privkey: privkey,
    );
  }

  static Future<Event> buildDeletionEvent({
    required String pubkey,
    required String privkey,
    required RelayPushSubscriptionRecord record,
  }) {
    final tags = <List<String>>[
      if (record.eventId.isNotEmpty) ['e', record.eventId],
      ['a', '$subscriptionKind:$pubkey:${record.d}'],
      ['k', subscriptionKind.toString()],
    ];
    return Event.from(
      kind: deletionKind,
      tags: tags,
      content: 'Nostr relay push subscription deleted',
      pubkey: pubkey,
      privkey: privkey,
    );
  }

  Future<void> sync({bool force = false}) {
    if (_syncFuture != null) return _syncFuture!;
    _syncFuture = _sync(force: force).whenComplete(() {
      _syncFuture = null;
    });
    return _syncFuture!;
  }

  Future<void> syncIfDue({bool force = false}) async {
    final pubkey = Account.sharedInstance.currentPubkey;
    if (pubkey.isEmpty) return;
    if (!force) {
      final lastSync = await _prefs.getInt(_lastSyncKey(pubkey)) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastSync < resyncInterval.inMilliseconds) return;
    }
    await sync(force: force);
  }

  Future<void> stopAndDelete({bool clearDeviceRegistration = true}) async {
    final account = Account.sharedInstance;
    final pubkey = account.currentPubkey;
    final privkey = account.currentPrivkey;
    if (pubkey.isNotEmpty && privkey.isNotEmpty) {
      final records = await _loadRecords(pubkey);
      for (final record in records.values) {
        try {
          final event = await buildDeletionEvent(
            pubkey: pubkey,
            privkey: privkey,
            record: record,
          );
          final ok = await _eventSender.send(event, record.relay);
          if (!ok.status) {
            LogUtils.w(() =>
                'NostrRelayPushService: delete failed on ${record.relay}: ${ok.message}');
          }
        } catch (e, stack) {
          LogUtils.e(() =>
              'NostrRelayPushService: delete error for ${record.relay}: $e, $stack');
        }
      }
      await _clearRecords(pubkey);
    }

    if (clearDeviceRegistration) {
      await PushTokenService().unregisterCurrentDevice(clearLocal: true);
    }
  }

  Future<void> _sync({required bool force}) async {
    LogUtils.v(() => 'NostrRelayPushService: sync start, force=$force');
    final account = Account.sharedInstance;
    if (!account.hasAuthenticatedSession) return;

    final notificationsEnabled =
        await _prefs.getBool(_notificationsEnabledKey) ?? true;
    if (!notificationsEnabled) {
      await stopAndDelete(clearDeviceRegistration: false);
      return;
    }

    final registration = await PushTokenService().getCurrentRegistration();
    if (registration == null || registration.callbackUrl.isEmpty) {
      LogUtils.v(() =>
          'NostrRelayPushService: skip sync, callback registration unavailable');
      return;
    }

    final pubkey = account.currentPubkey;
    final privkey = account.currentPrivkey;
    final existingRecords = await _loadRecords(pubkey);
    final candidateRelays = _candidateRelays();

    // Look up relay info concurrently — each lookup is an independent network
    // call, so doing them sequentially serializes N round-trips needlessly.
    final relayInfoResults = await Future.wait(
      candidateRelays.map((relay) async {
        try {
          final relayInfo = await _relayInfoProvider.getRelayDetails(relay);
          return (relay: relay, supported: relayInfo?.supportsNip9a == true);
        } catch (e) {
          LogUtils.w(() =>
              'NostrRelayPushService: failed to load relay info $relay: $e');
          return (relay: relay, supported: null);
        }
      }),
    );

    final supportedRelays = <String>{};
    int relayInfoFailures = 0;
    for (final result in relayInfoResults) {
      if (result.supported == null) {
        relayInfoFailures++;
      } else if (result.supported == true) {
        supportedRelays.add(normalizeRelayUrl(result.relay));
      }
    }

    // If every candidate relay failed to load (likely a network outage),
    // bail out and keep existing subscriptions intact rather than deleting them.
    if (supportedRelays.isEmpty &&
        relayInfoFailures == candidateRelays.length &&
        candidateRelays.isNotEmpty) {
      LogUtils.w(() =>
          'NostrRelayPushService: all $relayInfoFailures relay info lookups failed — aborting sync to preserve existing subscriptions');
      return;
    }

    // Send subscription events concurrently — each relay send blocks up to the
    // connection timeout, so serializing them multiplies the worst-case wait.
    final subscriptionResults = await Future.wait(
      supportedRelays.map((relay) async {
        final previous = existingRecords[relay];
        final d = previous?.d ?? generate64RandomHexChars();
        try {
          final event = await buildSubscriptionEvent(
            pubkey: pubkey,
            privkey: privkey,
            relay: relay,
            callbackUrl: registration.callbackUrl,
            d: d,
          );
          final ok = await _eventSender.send(event, relay);
          if (ok.status) {
            return MapEntry(
              relay,
              RelayPushSubscriptionRecord(
                relay: relay,
                d: d,
                eventId: event.id,
                callbackUrl: registration.callbackUrl,
                createdAt: event.createdAt,
              ),
            );
          }
          LogUtils.w(() =>
              'NostrRelayPushService: subscription rejected by $relay: ${ok.message}');
        } catch (e, stack) {
          LogUtils.e(() =>
              'NostrRelayPushService: subscription error for $relay: $e, $stack');
        }
        // On rejection or error, retain the previous record if one exists.
        return previous == null ? null : MapEntry(relay, previous);
      }),
    );

    final updatedRecords = <String, RelayPushSubscriptionRecord>{
      for (final entry in subscriptionResults)
        if (entry != null) entry.key: entry.value,
    };

    // Delete stale subscriptions concurrently.
    final staleRelays = existingRecords.keys
        .where((relay) => !supportedRelays.contains(relay))
        .toList();
    await Future.wait(
      staleRelays.map((relay) async {
        final record = existingRecords[relay];
        if (record == null) return;
        try {
          final event = await buildDeletionEvent(
            pubkey: pubkey,
            privkey: privkey,
            record: record,
          );
          await _eventSender.send(event, relay);
        } catch (e) {
          LogUtils.w(() =>
              'NostrRelayPushService: failed to delete stale subscription $relay: $e');
        }
      }),
    );

    await _saveRecords(pubkey, updatedRecords);
    await _prefs.setInt(
      _lastSyncKey(pubkey),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Set<String> _candidateRelays() {
    final me = Account.sharedInstance.me;
    final relays = <String>{};
    relays.addAll((me?.relayList ?? const <String>[]).map(normalizeRelayUrl));
    relays.addAll(
        (me?.inboxRelayList ?? const <String>[]).map(normalizeRelayUrl));
    relays.addAll((me?.dmRelayList ?? const <String>[]).map(normalizeRelayUrl));
    if (relays.isEmpty) {
      relays.addAll(
          Relays.sharedInstance.recommendGeneralRelays.map(normalizeRelayUrl));
    }
    relays.removeWhere((relay) =>
        relay.isEmpty ||
        (!relay.startsWith('ws://') && !relay.startsWith('wss://')));
    return relays;
  }

  Future<Map<String, RelayPushSubscriptionRecord>> _loadRecords(
      String pubkey) async {
    final raw = await _prefs.getString(_subscriptionsKey(pubkey));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final records = <String, RelayPushSubscriptionRecord>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          final record = RelayPushSubscriptionRecord.fromJson(value);
          if (record != null) {
            records[normalizeRelayUrl(record.relay)] = record;
          }
        }
      }
      return records;
    } catch (e) {
      LogUtils.w(() => 'NostrRelayPushService: invalid stored records: $e');
      return {};
    }
  }

  Future<void> _saveRecords(
    String pubkey,
    Map<String, RelayPushSubscriptionRecord> records,
  ) async {
    final json = records.map((relay, record) {
      return MapEntry(relay, record.toJson());
    });
    await _prefs.setString(_subscriptionsKey(pubkey), jsonEncode(json));
  }

  Future<void> _clearRecords(String pubkey) async {
    await _prefs.remove(_subscriptionsKey(pubkey));
    await _prefs.remove(_lastSyncKey(pubkey));
  }

  String _subscriptionsKey(String pubkey) {
    return '${_subscriptionsKeyPrefix}_$pubkey';
  }

  String _lastSyncKey(String pubkey) {
    return '${_lastSyncKeyPrefix}_$pubkey';
  }
}
