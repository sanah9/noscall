import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/core/call/contacts/contacts.dart';
import 'package:noscall/core/call/contacts/contacts_calling.dart';
import 'package:noscall/core/call/nip_ac_protocol.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  const senderPrivkey =
      '0000000000000000000000000000000000000000000000000000000000000001';
  const senderPubkey =
      '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
  const receiverPubkey =
      'c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5';

  tearDown(() {
    final contacts = Contacts.sharedInstance;
    contacts.onCallPaymentEvent = null;
    contacts.onIncomingCallOffer = null;
    contacts.onCallStateChange = null;
    contacts.callMessages.clear();
  });

  test('dispatches call payment events to payment handler only', () async {
    final contacts = Contacts.sharedInstance;
    Event? receivedPaymentEvent;
    String? receivedRelay;
    var callStateChanges = 0;
    contacts.onCallPaymentEvent = (event, relay) async {
      receivedPaymentEvent = event;
      receivedRelay = relay;
    };
    contacts.onCallStateChange = (friend, state, data, callId, callType) {
      callStateChanges += 1;
    };

    final event = await Event.from(
      kind: CallPaymentEventType.transfer.kind,
      tags: const [
        ['p', receiverPubkey],
        ['call-id', 'call-1'],
        ['payment-session-id', 'payment-session-1'],
        ['payment-type', 'transfer'],
      ],
      content: const CallPaymentEventCodec().encode(_payload()),
      pubkey: senderPubkey,
      privkey: senderPrivkey,
    );

    await contacts.handleCallEvent(event, 'wss://relay.example');

    expect(receivedPaymentEvent?.id, event.id);
    expect(receivedRelay, 'wss://relay.example');
    expect(callStateChanges, 0);
  });

  test('drops incoming offer when payment offer gate rejects it', () async {
    final contacts = Contacts.sharedInstance;
    contacts.pubkey = receiverPubkey;
    var gateCalls = 0;
    var callStateChanges = 0;
    contacts.onIncomingCallOffer = (event, signaling) async {
      gateCalls += 1;
      expect(event.pubkey, senderPubkey);
      expect(signaling.callId, 'call-1');
      return false;
    };
    contacts.onCallStateChange = (friend, state, data, callId, callType) {
      callStateChanges += 1;
    };

    final offer = await NipAcProtocol.createOffer(
      toPubkey: receiverPubkey,
      callId: 'call-1',
      callType: 'audio',
      sdp: 'v=0\no=alice',
      pubkey: senderPubkey,
      privkey: senderPrivkey,
    );

    await contacts.handleCallEvent(offer, 'wss://relay.example');

    expect(gateCalls, 1);
    expect(callStateChanges, 0);
    expect(contacts.callMessages.containsKey('call-1'), isFalse);
  });
}

CallPaymentEventPayload _payload() {
  return CallPaymentEventPayload(
    type: CallPaymentEventType.transfer,
    callId: 'call-1',
    paymentSessionId: 'payment-session-1',
    sequence: 1,
    purpose: CallPaymentPurpose.initial,
    callType: CallPaymentCallType.audio,
    payerPubkey: 'a' * 64,
    payeePubkey: 'b' * 64,
    mintUrl: CashuMintUrl.parse('https://mint.example'),
    amountSats: 10,
    billingPeriodSeconds: 60,
    coversFromSecond: 0,
    coversToSecond: 60,
    tokenHash: 'hash-1',
    createdAt: DateTime.utc(2026, 8, 14, 10),
    expiresAt: DateTime.utc(2026, 8, 14, 10, 1),
    token: 'cashuAey...',
  );
}
