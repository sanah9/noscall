import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  const codec = CallPaymentEventCodec();

  test('round-trips transfer payload with encrypted token field', () {
    final payload = _payload(
      type: CallPaymentEventType.transfer,
      token: 'cashuAey...',
    );

    final encoded = codec.encode(payload);
    final decoded = codec.decode(encoded);

    expect(decoded.type, CallPaymentEventType.transfer);
    expect(decoded.type.kind, 25055);
    expect(decoded.callId, payload.callId);
    expect(decoded.paymentSessionId, payload.paymentSessionId);
    expect(decoded.sequence, 1);
    expect(decoded.purpose, CallPaymentPurpose.initial);
    expect(decoded.callType, CallPaymentCallType.audio);
    expect(decoded.mintUrl, payload.mintUrl);
    expect(decoded.amountSats, 10);
    expect(decoded.tokenHash, 'hash-1');
    expect(decoded.token, 'cashuAey...');
  });

  test('omits token for ack payloads', () {
    final map = codec.encodeMap(_payload(type: CallPaymentEventType.ack));

    expect(map['type'], 'ack');
    expect(map['token'], isNull);
    expect(CallPaymentEventType.ack.kind, 25056);
  });

  test('maps required and refund event kinds', () {
    expect(CallPaymentEventType.required.kind, 25057);
    expect(CallPaymentEventType.refund.kind, 25058);
  });

  test('rejects unsupported versions', () {
    final map = codec.encodeMap(_payload(type: CallPaymentEventType.required));
    map['version'] = 2;

    expect(() => codec.decodeMap(map), throwsA(isA<FormatException>()));
  });

  test('rejects invalid payment coverage', () {
    expect(
      () => codec.encodeMap(
        _payload(
          type: CallPaymentEventType.transfer,
          coversFromSecond: 60,
          coversToSecond: 30,
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}

CallPaymentEventPayload _payload({
  required CallPaymentEventType type,
  String? token,
  int coversFromSecond = 0,
  int coversToSecond = 60,
}) {
  return CallPaymentEventPayload(
    type: type,
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
    coversFromSecond: coversFromSecond,
    coversToSecond: coversToSecond,
    tokenHash: 'hash-1',
    createdAt: DateTime.utc(2026, 8, 14, 10),
    expiresAt: DateTime.utc(2026, 8, 14, 10, 1),
    token: token,
  );
}
