import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_nostr_gateway.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_nostr_policy_query.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_policy_event_codec.dart';
import 'package:noscall/core/call/nip_ac_protocol.dart';
import 'package:noscall/core/common/network/connect.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  test('sends policy query and resolves matching encrypted response', () async {
    final relaySender = _FakePaymentRelaySender();
    final gateway = CallPaymentNostrGateway(
      pubkey: _requesterPubkey,
      privkey: _requesterPrivkey,
      relaySender: relaySender,
    );
    final subscriber = _FakePolicyResponseSubscriber();
    final query = CallPaymentNostrPolicyQuery(
      pubkey: _requesterPubkey,
      privkey: _requesterPrivkey,
      gateway: gateway,
      subscriber: subscriber,
      requestIdFactory: () => 'policy-request-1',
      clock: () => DateTime.utc(2026, 8, 14, 10),
      timeout: const Duration(seconds: 1),
    );

    final future = query.query(_responderPubkey);
    await Future<void>.delayed(Duration.zero);

    expect(subscriber.receiverPubkeys.single, _requesterPubkey);
    expect(relaySender.events.single.kind, NipAcProtocol.wrapKind);

    final queryInner = await NipAcProtocol.unwrap(
      relaySender.events.single,
      _responderPubkey,
      _responderPrivkey,
    );
    expect(queryInner.kind, CallPaymentPolicyEventType.query.kind);
    final queryPayload = const CallPaymentPolicyEventCodec().decode(
      queryInner.content,
    );
    expect(queryPayload.requestId, 'policy-request-1');
    expect(queryPayload.requesterPubkey, _requesterPubkey);
    expect(queryPayload.responderPubkey, _responderPubkey);

    final responderGateway = CallPaymentNostrGateway(
      pubkey: _responderPubkey,
      privkey: _responderPrivkey,
    );
    final responseInner = await responderGateway.createPolicyInnerEvent(
      receiverPubkey: _requesterPubkey,
      payload: CallPaymentPolicyEventPayload(
        type: CallPaymentPolicyEventType.response,
        requestId: 'policy-request-1',
        requesterPubkey: _requesterPubkey,
        responderPubkey: _responderPubkey,
        policy: _policy(),
        createdAt: DateTime.utc(2026, 8, 14, 10, 0, 1),
      ),
    );
    final wrappedResponse = await NipAcProtocol.wrap(
      responseInner,
      _requesterPubkey,
      includeKindMarker: true,
    );

    await subscriber.emit(wrappedResponse, 'wss://relay.example');

    final policy = await future;
    expect(policy?.owner.value, _responderPubkey);
    expect(policy?.audioPriceSatsPerMinute, 10);
    expect(subscriber.closedSubscriptionIds, ['policy-subscription-1']);
  });

  test('returns null when query event send fails', () async {
    final gateway = CallPaymentNostrGateway(
      pubkey: _requesterPubkey,
      privkey: _requesterPrivkey,
      relaySender: _FailingPaymentRelaySender(),
    );
    final subscriber = _FakePolicyResponseSubscriber();
    final query = CallPaymentNostrPolicyQuery(
      pubkey: _requesterPubkey,
      privkey: _requesterPrivkey,
      gateway: gateway,
      subscriber: subscriber,
      requestIdFactory: () => 'policy-request-1',
      timeout: const Duration(seconds: 1),
    );

    final policy = await query.query(_responderPubkey);

    expect(policy, isNull);
    expect(subscriber.closedSubscriptionIds, ['policy-subscription-1']);
  });

  test(
    'ignores policy responses when routing tags do not match payload',
    () async {
      final relaySender = _FakePaymentRelaySender();
      final gateway = CallPaymentNostrGateway(
        pubkey: _requesterPubkey,
        privkey: _requesterPrivkey,
        relaySender: relaySender,
      );
      final subscriber = _FakePolicyResponseSubscriber();
      final query = CallPaymentNostrPolicyQuery(
        pubkey: _requesterPubkey,
        privkey: _requesterPrivkey,
        gateway: gateway,
        subscriber: subscriber,
        requestIdFactory: () => 'policy-request-1',
        clock: () => DateTime.utc(2026, 8, 14, 10),
        timeout: const Duration(seconds: 1),
      );

      final future = query.query(_responderPubkey);
      await Future<void>.delayed(Duration.zero);

      final malformedInner = await _responseInnerEvent(
        requestId: 'policy-request-1',
        tags: [
          ['p', _requesterPubkey],
          ['payment-policy-request-id', 'other-request'],
          ['payment-policy-type', CallPaymentPolicyEventType.response.value],
        ],
      );
      await subscriber.emit(
        await NipAcProtocol.wrap(
          malformedInner,
          _requesterPubkey,
          includeKindMarker: true,
        ),
        'wss://relay.example',
      );

      final matchingInner = await _responseInnerEvent(
        requestId: 'policy-request-1',
      );
      await subscriber.emit(
        await NipAcProtocol.wrap(
          matchingInner,
          _requesterPubkey,
          includeKindMarker: true,
        ),
        'wss://relay.example',
      );

      final policy = await future;
      expect(policy?.owner.value, _responderPubkey);
      expect(subscriber.closedSubscriptionIds, ['policy-subscription-1']);
    },
  );
}

const _requesterPrivkey =
    '0000000000000000000000000000000000000000000000000000000000000001';
const _requesterPubkey =
    '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
const _responderPrivkey =
    '0000000000000000000000000000000000000000000000000000000000000002';
const _responderPubkey =
    'c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5';
final _mintUrl = CashuMintUrl.parse('https://mint.example');

Future<Event> _responseInnerEvent({
  required String requestId,
  List<List<String>>? tags,
}) {
  final payload = CallPaymentPolicyEventPayload(
    type: CallPaymentPolicyEventType.response,
    requestId: requestId,
    requesterPubkey: _requesterPubkey,
    responderPubkey: _responderPubkey,
    policy: _policy(),
    createdAt: DateTime.utc(2026, 8, 14, 10, 0, 1),
  );
  return Event.from(
    kind: payload.type.kind,
    tags:
        tags ??
        [
          ['p', _requesterPubkey],
          ['payment-policy-request-id', payload.requestId],
          ['payment-policy-type', payload.type.value],
        ],
    content: const CallPaymentPolicyEventCodec().encode(payload),
    pubkey: _responderPubkey,
    privkey: _responderPrivkey,
  );
}

CallPaymentPolicy _policy() {
  return CallPaymentPolicy(
    owner: CashuAccountId.fromNostrPubkey(_responderPubkey),
    enabled: true,
    freePolicy: CallPaymentFreePolicy.contactsFree,
    freePubkeys: [_requesterPubkey],
    audioPriceSatsPerMinute: 10,
    videoPriceSatsPerMinute: 30,
    billingPeriodSeconds: 60,
    gracePeriodSeconds: 10,
    acceptedMintUrls: [_mintUrl],
    createdAt: DateTime.utc(2026, 8, 14, 9),
    updatedAt: DateTime.utc(2026, 8, 14, 9),
  );
}

final class _FakePolicyResponseSubscriber
    implements CallPaymentPolicyResponseSubscriber {
  final List<String> receiverPubkeys = [];
  final List<String> closedSubscriptionIds = [];
  CallPaymentWrappedEventCallback? onEvent;

  @override
  String subscribe({
    required String receiverPubkey,
    required int since,
    required CallPaymentWrappedEventCallback onEvent,
  }) {
    receiverPubkeys.add(receiverPubkey);
    this.onEvent = onEvent;
    return 'policy-subscription-1';
  }

  Future<void> emit(Event event, String relay) async {
    await onEvent?.call(event, relay);
  }

  @override
  Future<void> close(String subscriptionId) async {
    closedSubscriptionIds.add(subscriptionId);
  }
}

final class _FakePaymentRelaySender implements CallPaymentRelaySender {
  final List<Event> events = [];

  @override
  void send(
    Event event, {
    required OKCallBack sendCallBack,
    List<RelayKind> relayKinds = const [RelayKind.general],
  }) {
    events.add(event);
    sendCallBack(OKEvent(event.id, true, 'ok'), 'wss://relay.example');
  }
}

final class _FailingPaymentRelaySender implements CallPaymentRelaySender {
  @override
  void send(
    Event event, {
    required OKCallBack sendCallBack,
    List<RelayKind> relayKinds = const [RelayKind.general],
  }) {
    sendCallBack(OKEvent(event.id, false, 'failed'), 'wss://relay.example');
  }
}
