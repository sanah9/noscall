import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/call_payments/application/call_payment_ack_service.dart';
import 'package:noscall/call_payments/application/call_payment_event_handler.dart';
import 'package:noscall/call_payments/application/call_payment_incoming_transfer_service.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  test('dispatches transfer payloads to incoming transfer service', () async {
    CallPaymentIncomingTransferRequest? receivedRequest;
    final handler = CallPaymentEventHandler(
      owner: _owner,
      receiveTransfer: (request) async {
        receivedRequest = request;
        return _incomingResult();
      },
      applyAck: (_) async => throw StateError('ack should not be called'),
      resolveCallType: (_, _) => CallPaymentCallType.audio,
    );

    final result = await handler.handle(
      await _event(_payload(type: CallPaymentEventType.transfer)),
    );

    expect(result.handled, isTrue);
    expect(result.type, CallPaymentEventType.transfer);
    expect(receivedRequest?.owner, _owner);
    expect(receivedRequest?.senderPubkey, _senderPubkey);
    expect(receivedRequest?.callType, CallPaymentCallType.audio);
    expect(receivedRequest?.payload.type, CallPaymentEventType.transfer);
  });

  test('dispatches ack payloads to ack service', () async {
    CallPaymentAckRequest? receivedRequest;
    final handler = CallPaymentEventHandler(
      owner: _owner,
      receiveTransfer: (_) async =>
          throw StateError('transfer should not be called'),
      applyAck: (request) async {
        receivedRequest = request;
        return _ackResult();
      },
      resolveCallType: (_, _) => CallPaymentCallType.audio,
    );

    final result = await handler.handle(
      await _event(_payload(type: CallPaymentEventType.ack)),
    );

    expect(result.handled, isTrue);
    expect(result.type, CallPaymentEventType.ack);
    expect(receivedRequest?.owner, _owner);
    expect(receivedRequest?.senderPubkey, _senderPubkey);
    expect(receivedRequest?.payload.type, CallPaymentEventType.ack);
  });

  test('ignores payment event types that are not implemented yet', () async {
    final handler = CallPaymentEventHandler(
      owner: _owner,
      receiveTransfer: (_) async =>
          throw StateError('transfer should not be called'),
      applyAck: (_) async => throw StateError('ack should not be called'),
      resolveCallType: (_, _) => CallPaymentCallType.audio,
    );

    final result = await handler.handle(
      await _event(_payload(type: CallPaymentEventType.required)),
    );

    expect(result.handled, isFalse);
    expect(result.type, CallPaymentEventType.required);
    expect(result.ignoredReason, 'payment_event_type_not_supported_yet');
  });
}

const _senderPrivkey =
    '0000000000000000000000000000000000000000000000000000000000000001';
const _senderPubkey =
    '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
final _owner = CashuAccountId.fromNostrPubkey('b' * 64);
final _mintUrl = CashuMintUrl.parse('https://mint.example');

Future<Event> _event(CallPaymentEventPayload payload) {
  return Event.from(
    kind: payload.type.kind,
    tags: [
      ['p', _owner.value],
      ['call-id', payload.callId],
      ['payment-session-id', payload.paymentSessionId],
      ['payment-type', payload.type.value],
    ],
    content: const CallPaymentEventCodec().encode(payload),
    pubkey: _senderPubkey,
    privkey: _senderPrivkey,
  );
}

CallPaymentEventPayload _payload({required CallPaymentEventType type}) {
  return CallPaymentEventPayload(
    type: type,
    callId: 'call-1',
    paymentSessionId: 'payment-session-1',
    sequence: 1,
    purpose: CallPaymentPurpose.initial,
    payerPubkey: _senderPubkey,
    payeePubkey: _owner.value,
    mintUrl: _mintUrl,
    amountSats: 10,
    billingPeriodSeconds: 60,
    coversFromSecond: 0,
    coversToSecond: 60,
    tokenHash: 'hash-1',
    createdAt: DateTime.utc(2026, 8, 14, 10),
    expiresAt: DateTime.utc(2026, 8, 14, 10, 1),
    token: type == CallPaymentEventType.transfer ? 'cashuAey' : null,
  );
}

CallPaymentIncomingTransferResult _incomingResult() {
  final now = DateTime.utc(2026, 8, 14, 10);
  return CallPaymentIncomingTransferResult(
    session: _session(now),
    installment: _installment(now, CallPaymentTransferDirection.received),
    ackEvent: OKEvent('ack', true, 'ok'),
  );
}

CallPaymentAckResult _ackResult() {
  final now = DateTime.utc(2026, 8, 14, 10);
  return CallPaymentAckResult(
    session: _session(now),
    installment: _installment(now, CallPaymentTransferDirection.sent),
  );
}

CallPaymentSession _session(DateTime now) {
  return CallPaymentSession(
    owner: _owner,
    callId: 'call-1',
    peerPubkey: _senderPubkey,
    direction: CallPaymentCallDirection.incoming,
    role: CallPaymentRole.payee,
    callType: CallPaymentCallType.audio,
    status: CallPaymentSessionStatus.ringing,
    mintUrl: _mintUrl,
    priceSatsPerMinute: 10,
    billingPeriodSeconds: 60,
    maxSpendSats: 10,
    connectedDurationSeconds: 0,
    chargedSats: 10,
    refundedSats: 0,
    createdAt: now,
    updatedAt: now,
  );
}

CallPaymentInstallment _installment(
  DateTime now,
  CallPaymentTransferDirection direction,
) {
  return CallPaymentInstallment(
    owner: _owner,
    callId: 'call-1',
    paymentSessionId: 'payment-session-1',
    sequence: 1,
    purpose: CallPaymentPurpose.initial,
    direction: direction,
    amountSats: 10,
    mintUrl: _mintUrl,
    status: CallPaymentInstallmentStatus.claimed,
    coversFromSecond: 0,
    coversToSecond: 60,
    createdAt: now,
    updatedAt: now,
  );
}
