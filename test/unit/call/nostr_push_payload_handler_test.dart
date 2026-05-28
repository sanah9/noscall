import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call/nostr_push_payload_handler.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import 'package:noscall/core/call/contacts/contacts.dart';
import 'package:noscall/core/call/nip_ac_protocol.dart';
import 'package:noscall/core/common/network/event_cache.dart';
import 'package:noscall/core/common/thread/thread_pool_manager.dart';
import 'package:nostr_core_dart/nostr.dart';

void main() {
  const senderPrivkey =
      '0000000000000000000000000000000000000000000000000000000000000001';
  const senderPubkey =
      '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
  const receiverPrivkey =
      '0000000000000000000000000000000000000000000000000000000000000002';
  const receiverPubkey =
      'c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5';

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await ThreadPoolManager.sharedInstance.initialize();
  });

  tearDownAll(() {
    ThreadPoolManager.sharedInstance.dispose();
  });

  setUp(() {
    Account.sharedInstance.currentPubkey = receiverPubkey;
    Account.sharedInstance.currentPrivkey = receiverPrivkey;
    final contacts = Contacts.sharedInstance;
    contacts.pubkey = receiverPubkey;
    contacts.privkey = receiverPrivkey;
    contacts.blockList = [];
    contacts.allContacts = {
      senderPubkey: UserDBISAR(pubKey: senderPubkey),
    };
    contacts.callMessages.clear();
    EventCache.sharedInstance.cacheIds.clear();
  });

  tearDown(() {
    Account.sharedInstance.currentPubkey = '';
    Account.sharedInstance.currentPrivkey = '';
    final contacts = Contacts.sharedInstance;
    contacts.pubkey = '';
    contacts.privkey = '';
    contacts.blockList = null;
    contacts.allContacts.clear();
    contacts.callMessages.clear();
    contacts.onCallStateChange = null;
    EventCache.sharedInstance.cacheIds.clear();
  });

  test('handles NIP-9a payload and dispatches incoming offer', () async {
    String? receivedFriend;
    SignalingState? receivedState;
    String? receivedCallId;
    String? receivedCallType;
    Contacts.sharedInstance.onCallStateChange =
        (friend, state, data, callId, callType) {
      receivedFriend = friend;
      receivedState = state;
      receivedCallId = callId;
      receivedCallType = callType;
    };

    final wrapped = await _wrappedOffer();
    final handled = await NostrPushPayloadHandler().handle({
      'type': NostrPushPayloadHandler.payloadType,
      'id': wrapped.id,
      'relay': 'wss://relay.example.com',
      'event': wrapped.toJson(),
    });

    expect(handled, isTrue);
    expect(receivedFriend, senderPubkey);
    expect(receivedState, SignalingState.offer);
    expect(receivedCallId, 'call-push-001');
    expect(receivedCallType, 'voice');
  });

  test('rejects duplicate push payloads', () async {
    final wrapped = await _wrappedOffer();
    final payload = {
      'type': NostrPushPayloadHandler.payloadType,
      'id': wrapped.id,
      'relay': 'wss://relay.example.com',
      'event': wrapped.toJson(),
    };

    expect(await NostrPushPayloadHandler().handle(payload), isTrue);
    expect(await NostrPushPayloadHandler().handle(payload), isFalse);
  });

  test('rejects payloads not addressed to current user', () async {
    final offer = await NipAcProtocol.createOffer(
      toPubkey: senderPubkey,
      callId: 'call-wrong-recipient',
      callType: 'voice',
      sdp: 'v=0\no=wrong',
      pubkey: senderPubkey,
      privkey: senderPrivkey,
    );
    final wrapped = await NipAcProtocol.wrap(offer, senderPubkey);

    final handled = await NostrPushPayloadHandler().handle({
      'type': NostrPushPayloadHandler.payloadType,
      'id': wrapped.id,
      'relay': 'wss://relay.example.com',
      'event': wrapped.toJson(),
    });

    expect(handled, isFalse);
  });

  test('rejects blocked callers', () async {
    Contacts.sharedInstance.blockList = [senderPubkey];
    final wrapped = await _wrappedOffer();

    final handled = await NostrPushPayloadHandler().handle({
      'type': NostrPushPayloadHandler.payloadType,
      'id': wrapped.id,
      'relay': 'wss://relay.example.com',
      'event': wrapped.toJson(),
    });

    expect(handled, isFalse);
  });

  test('rejects stale offers', () async {
    final staleCreatedAt =
        currentUnixTimestampSeconds() - Contacts.callEventStaleSeconds - 1;
    final offer = await NipAcProtocol.createOffer(
      toPubkey: receiverPubkey,
      callId: 'call-stale',
      callType: 'voice',
      sdp: 'v=0\no=stale',
      pubkey: senderPubkey,
      privkey: senderPrivkey,
    );
    final staleOffer = await Event.from(
      kind: offer.kind,
      tags: offer.tags,
      content: offer.content,
      pubkey: senderPubkey,
      privkey: senderPrivkey,
      createdAt: staleCreatedAt,
    );
    final wrapped = await NipAcProtocol.wrap(staleOffer, receiverPubkey);

    final handled = await NostrPushPayloadHandler().handle({
      'type': NostrPushPayloadHandler.payloadType,
      'id': wrapped.id,
      'relay': 'wss://relay.example.com',
      'event': wrapped.toJson(),
    });

    expect(handled, isFalse);
  });
}

Future<Event> _wrappedOffer() async {
  const senderPrivkey =
      '0000000000000000000000000000000000000000000000000000000000000001';
  const senderPubkey =
      '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
  const receiverPubkey =
      'c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5';
  final offer = await NipAcProtocol.createOffer(
    toPubkey: receiverPubkey,
    callId: 'call-push-001',
    callType: 'voice',
    sdp: 'v=0\no=push',
    pubkey: senderPubkey,
    privkey: senderPrivkey,
  );
  return NipAcProtocol.wrap(offer, receiverPubkey);
}
