import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_nostr_gateway.dart';
import 'package:noscall/core/call/nip_ac_protocol.dart';
import 'package:noscall/core/common/network/connect.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  const senderPrivkey =
      '0000000000000000000000000000000000000000000000000000000000000001';
  const senderPubkey =
      '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
  const receiverPrivkey =
      '0000000000000000000000000000000000000000000000000000000000000002';
  const receiverPubkey =
      'c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5';

  test('creates signed inner payment events with call payment tags', () async {
    final gateway = CallPaymentNostrGateway(
      pubkey: senderPubkey,
      privkey: senderPrivkey,
    );

    final innerEvent = await gateway.createInnerEvent(
      receiverPubkey: receiverPubkey,
      payload: _payload(),
    );

    expect(innerEvent.kind, CallPaymentEventType.transfer.kind);
    expect(innerEvent.pubkey, senderPubkey);
    expect(_tag(innerEvent, 'p'), receiverPubkey);
    expect(_tag(innerEvent, 'call-id'), 'call-1');
    expect(_tag(innerEvent, 'payment-session-id'), 'payment-session-1');
    expect(_tag(innerEvent, 'payment-type'), 'transfer');

    final decoded = const CallPaymentEventCodec().decode(innerEvent.content);
    expect(decoded.amountSats, 10);
    expect(decoded.token, 'cashuAey...');
  });

  test(
    'wraps payment events with NIP-AC 21059 envelope before sending',
    () async {
      final sender = _FakePaymentRelaySender();
      final gateway = CallPaymentNostrGateway(
        pubkey: senderPubkey,
        privkey: senderPrivkey,
        relaySender: sender,
      );

      final ok = await gateway.send(
        receiverPubkey: receiverPubkey,
        payload: _payload(),
      );

      expect(ok.status, isTrue);
      expect(sender.events.single.kind, NipAcProtocol.wrapKind);
      expect(sender.relayKinds.single, RelayKind.general);

      final innerEvent = await NipAcProtocol.unwrap(
        sender.events.single,
        receiverPubkey,
        receiverPrivkey,
      );
      expect(innerEvent.id, ok.eventId);
      expect(innerEvent.kind, CallPaymentEventType.transfer.kind);
      expect(
        const CallPaymentEventCodec().decode(innerEvent.content).callId,
        'call-1',
      );
    },
  );

  test(
    'returns failed ok event when relays do not acknowledge before timeout',
    () async {
      final gateway = CallPaymentNostrGateway(
        pubkey: senderPubkey,
        privkey: senderPrivkey,
        relaySender: _SilentPaymentRelaySender(),
        sendTimeout: const Duration(milliseconds: 1),
      );

      final ok = await gateway.send(
        receiverPubkey: receiverPubkey,
        payload: _payload(),
      );

      expect(ok.status, isFalse);
      expect(ok.message, 'payment event send timeout');
    },
  );
}

CallPaymentEventPayload _payload() {
  return CallPaymentEventPayload(
    type: CallPaymentEventType.transfer,
    callId: 'call-1',
    paymentSessionId: 'payment-session-1',
    sequence: 1,
    purpose: CallPaymentPurpose.initial,
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

String? _tag(Event event, String key) {
  for (final tag in event.tags) {
    if (tag.length >= 2 && tag[0] == key) return tag[1];
  }
  return null;
}

final class _FakePaymentRelaySender implements CallPaymentRelaySender {
  final List<Event> events = [];
  final List<RelayKind> relayKinds = [];

  @override
  void send(
    Event event, {
    required OKCallBack sendCallBack,
    List<RelayKind> relayKinds = const [RelayKind.general],
  }) {
    events.add(event);
    this.relayKinds.addAll(relayKinds);
    sendCallBack(OKEvent(event.id, true, 'ok'), 'wss://relay.example');
  }
}

final class _SilentPaymentRelaySender implements CallPaymentRelaySender {
  @override
  void send(
    Event event, {
    required OKCallBack sendCallBack,
    List<RelayKind> relayKinds = const [RelayKind.general],
  }) {}
}
