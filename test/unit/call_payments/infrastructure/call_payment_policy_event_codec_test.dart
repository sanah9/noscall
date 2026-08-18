import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_policy_event_codec.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  const codec = CallPaymentPolicyEventCodec();

  test('round-trips policy query payload', () {
    final payload = CallPaymentPolicyEventPayload(
      type: CallPaymentPolicyEventType.query,
      requestId: 'policy-request-1',
      requesterPubkey: _requesterPubkey,
      responderPubkey: _responderPubkey,
      createdAt: DateTime.utc(2026, 8, 14, 10),
    );

    final decoded = codec.decode(codec.encode(payload));

    expect(decoded.type, CallPaymentPolicyEventType.query);
    expect(decoded.type.kind, 25059);
    expect(decoded.requestId, 'policy-request-1');
    expect(decoded.policy, isNull);
  });

  test('round-trips policy response payload', () {
    final payload = CallPaymentPolicyEventPayload(
      type: CallPaymentPolicyEventType.response,
      requestId: 'policy-request-1',
      requesterPubkey: _requesterPubkey,
      responderPubkey: _responderPubkey,
      policy: _policy(),
      createdAt: DateTime.utc(2026, 8, 14, 10),
    );

    final decoded = codec.decode(codec.encode(payload));

    expect(decoded.type, CallPaymentPolicyEventType.response);
    expect(decoded.type.kind, 25060);
    expect(decoded.policy?.owner.value, _responderPubkey);
    expect(decoded.policy?.enabled, isTrue);
    expect(decoded.policy?.freePolicy, CallPaymentFreePolicy.contactsFree);
    expect(decoded.policy?.audioPriceSatsPerMinute, 10);
    expect(decoded.policy?.acceptedMintUrls.single, _mintUrl);
  });

  test('rejects response without policy', () {
    final payload = CallPaymentPolicyEventPayload(
      type: CallPaymentPolicyEventType.response,
      requestId: 'policy-request-1',
      requesterPubkey: _requesterPubkey,
      responderPubkey: _responderPubkey,
      createdAt: DateTime.utc(2026, 8, 14, 10),
    );

    expect(() => codec.encodeMap(payload), throwsA(isA<ArgumentError>()));
  });
}

const _requesterPubkey =
    '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
const _responderPubkey =
    'c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5';
final _mintUrl = CashuMintUrl.parse('https://mint.example');

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
