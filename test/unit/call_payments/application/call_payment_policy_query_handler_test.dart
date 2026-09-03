import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/call_payments/application/call_payment_policy_query_handler.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/domain/call_payment_repositories.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_policy_event_codec.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  test('responds to policy query with local policy', () async {
    final sender = _PolicyResponseSender();
    final handler = _handler(
      policyRepository: _PolicyRepository()..policy = _policy(),
      sender: sender,
    );

    final result = await handler.handle(await _queryEvent());

    expect(result.handled, isTrue);
    expect(result.responseEvent?.status, isTrue);
    expect(sender.receiverPubkeys.single, _requesterPubkey);
    expect(sender.payloads.single.type, CallPaymentPolicyEventType.response);
    expect(sender.payloads.single.requestId, 'policy-request-1');
    expect(sender.payloads.single.policy?.enabled, isTrue);
    expect(sender.payloads.single.policy?.acceptedMintUrls.single, _mintUrl);
  });

  test(
    'responds with disabled default policy when local policy is missing',
    () async {
      final sender = _PolicyResponseSender();
      final handler = _handler(
        policyRepository: _PolicyRepository(),
        sender: sender,
      );

      final result = await handler.handle(await _queryEvent());

      expect(result.handled, isTrue);
      expect(sender.payloads.single.policy?.enabled, isFalse);
      expect(sender.payloads.single.policy?.owner, _owner);
      expect(sender.payloads.single.policy?.acceptedMintUrls, isEmpty);
    },
  );

  test('ignores policy query for another responder', () async {
    final sender = _PolicyResponseSender();
    final handler = _handler(
      policyRepository: _PolicyRepository()..policy = _policy(),
      sender: sender,
    );

    final result = await handler.handle(
      await _queryEvent(responderPubkey: 'c' * 64),
    );

    expect(result.handled, isFalse);
    expect(result.ignoredReason, 'policy_query_participants_mismatch');
    expect(sender.payloads, isEmpty);
  });

  test(
    'ignores policy queries when routing tags do not match payload',
    () async {
      final sender = _PolicyResponseSender();
      final handler = _handler(
        policyRepository: _PolicyRepository()..policy = _policy(),
        sender: sender,
      );

      final result = await handler.handle(
        await _queryEvent(
          tags: [
            ['p', _responderPubkey],
            ['payment-policy-request-id', 'other-request'],
            ['payment-policy-type', CallPaymentPolicyEventType.query.value],
          ],
        ),
      );

      expect(result.handled, isFalse);
      expect(result.ignoredReason, 'policy_query_tag_mismatch');
      expect(sender.payloads, isEmpty);
    },
  );
}

const _requesterPrivkey =
    '0000000000000000000000000000000000000000000000000000000000000001';
const _requesterPubkey =
    '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
const _responderPubkey =
    'c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5';
final _owner = CashuAccountId.fromNostrPubkey(_responderPubkey);
final _mintUrl = CashuMintUrl.parse('https://mint.example');

CallPaymentPolicyQueryHandler _handler({
  required _PolicyRepository policyRepository,
  required _PolicyResponseSender sender,
}) {
  return CallPaymentPolicyQueryHandler(
    owner: _owner,
    policyRepository: policyRepository,
    sendResponse: sender.send,
    clock: () => DateTime.utc(2026, 8, 14, 10),
  );
}

Future<Event> _queryEvent({String? responderPubkey, List<List<String>>? tags}) {
  final payload = CallPaymentPolicyEventPayload(
    type: CallPaymentPolicyEventType.query,
    requestId: 'policy-request-1',
    requesterPubkey: _requesterPubkey,
    responderPubkey: responderPubkey ?? _responderPubkey,
    createdAt: DateTime.utc(2026, 8, 14, 10),
  );
  return Event.from(
    kind: payload.type.kind,
    tags:
        tags ??
        [
          ['p', payload.responderPubkey],
          ['payment-policy-request-id', payload.requestId],
          ['payment-policy-type', payload.type.value],
        ],
    content: const CallPaymentPolicyEventCodec().encode(payload),
    pubkey: _requesterPubkey,
    privkey: _requesterPrivkey,
  );
}

CallPaymentPolicy _policy() {
  return CallPaymentPolicy(
    owner: _owner,
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

final class _PolicyResponseSender {
  final List<String> receiverPubkeys = [];
  final List<CallPaymentPolicyEventPayload> payloads = [];

  Future<OKEvent> send({
    required String receiverPubkey,
    required CallPaymentPolicyEventPayload payload,
  }) async {
    receiverPubkeys.add(receiverPubkey);
    payloads.add(payload);
    return OKEvent('policy-response-1', true, 'ok');
  }
}

final class _PolicyRepository implements CallPaymentPolicyRepository {
  CallPaymentPolicy? policy;

  @override
  Future<CallPaymentPolicy?> find(CashuAccountId owner) async {
    if (policy?.owner != owner) return null;
    return policy;
  }

  @override
  Future<void> save(CallPaymentPolicy policy) async {
    this.policy = policy;
  }
}
