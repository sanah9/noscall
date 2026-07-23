import 'dart:convert';

import 'package:nostr_core_dart/nostr.dart';

import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/call/call_event_policy.dart';
import 'package:noscall/core/call/contacts/contacts.dart';
import 'package:noscall/core/call/contacts/contacts_blocklist.dart';
import 'package:noscall/core/call/contacts/contacts_calling.dart';
import 'package:noscall/core/call/contacts/contacts_isolate_event.dart';
import 'package:noscall/core/call/nip_ac_protocol.dart';
import 'package:noscall/core/common/network/event_cache.dart';
import 'package:noscall/core/common/utils/log_utils.dart';

class NostrPushPayloadHandler {
  NostrPushPayloadHandler._internal();
  factory NostrPushPayloadHandler() => sharedInstance;
  static final NostrPushPayloadHandler sharedInstance =
      NostrPushPayloadHandler._internal();

  static const String payloadType = 'nostr_relay_push';

  bool isNostrRelayPushPayload(Map<String, dynamic> payload) {
    return payload['type'] == payloadType ||
        (payload.containsKey('id') &&
            payload.containsKey('relay') &&
            payload.containsKey('event'));
  }

  Future<bool> handle(Map<String, dynamic> payload) async {
    if (!isNostrRelayPushPayload(payload)) return false;
    final relay = payload['relay']?.toString() ?? '';
    final expectedId = payload['id']?.toString() ?? '';
    final eventJson = _decodeEventJson(payload['event']);
    if (relay.isEmpty || expectedId.isEmpty || eventJson == null) {
      LogUtils.w(() => 'NostrPushPayloadHandler: invalid payload shape');
      return false;
    }

    late final Event event;
    try {
      event = await Event.fromJson(eventJson, verify: false);
    } catch (e) {
      LogUtils.w(() => 'NostrPushPayloadHandler: invalid event JSON: $e');
      return false;
    }
    if (event.id != expectedId) {
      LogUtils.w(() => 'NostrPushPayloadHandler: event id mismatch');
      return false;
    }
    if (!await event.isValid()) {
      LogUtils.w(() => 'NostrPushPayloadHandler: invalid event signature');
      return false;
    }
    if (event.kind != NipAcProtocol.wrapKind) {
      LogUtils.v(
        () =>
            'NostrPushPayloadHandler: ignored non NIP-AC wrapper kind=${event.kind}',
      );
      return false;
    }

    final myPubkey = Account.sharedInstance.currentPubkey;
    if (myPubkey.isEmpty ||
        !_tagContains(event.tags, 'p', myPubkey) ||
        !_tagContains(event.tags, 'k', NipAcKind.offer.value.toString())) {
      LogUtils.v(
        () =>
            'NostrPushPayloadHandler: ignored wrapper not addressed to current offer',
      );
      return false;
    }

    final contacts = Contacts.sharedInstance;
    final innerEvent = await contacts.decodeNipAcWrapEvent(event);
    if (innerEvent == null || innerEvent.kind != NipAcKind.offer.value) {
      LogUtils.v(() => 'NostrPushPayloadHandler: ignored non-offer payload');
      return false;
    }
    if (EventCache.sharedInstance.cacheIds.contains(innerEvent.id)) {
      LogUtils.v(
        () => 'NostrPushPayloadHandler: duplicate inner event ${innerEvent.id}',
      );
      return false;
    }
    if (CallEventPolicy.isStale(
      innerEvent,
      nowSeconds: currentUnixTimestampSeconds(),
      staleAfterSeconds: Contacts.callEventStaleSeconds,
    )) {
      LogUtils.v(
        () => 'NostrPushPayloadHandler: stale inner event ${innerEvent.id}',
      );
      return false;
    }
    if (!CallEventPolicy.isFollowedCaller(
      callerPubkey: innerEvent.pubkey,
      myPubkey: contacts.pubkey,
      followedPubkeys: contacts.allContacts.keys.toSet(),
    )) {
      LogUtils.v(
        () =>
            'NostrPushPayloadHandler: caller not followed ${innerEvent.pubkey}',
      );
      return false;
    }
    if (contacts.inBlockList(innerEvent.pubkey)) {
      LogUtils.v(
        () => 'NostrPushPayloadHandler: caller blocked ${innerEvent.pubkey}',
      );
      return false;
    }

    await EventCache.sharedInstance.receiveEvent(innerEvent, relay);
    contacts.updateFriendMessageTime(innerEvent.createdAt, relay);
    await contacts.handleCallEvent(innerEvent, relay);
    return true;
  }

  Map<String, dynamic>? _decodeEventJson(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  bool _tagContains(List<List<String>> tags, String name, String value) {
    return tags.any(
      (tag) => tag.length >= 2 && tag[0] == name && tag[1] == value,
    );
  }
}
