import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/call_payments/application/call_payment_ack_service.dart';
import 'package:noscall/call_payments/application/call_payment_event_handler.dart';
import 'package:noscall/call_payments/application/call_payment_incoming_transfer_service.dart';
import 'package:noscall/call_payments/application/call_payment_refund_service.dart';
import 'package:noscall/call_payments/application/call_payment_required_service.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_policy_event_codec.dart';
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
      receiveRefund: (_) async =>
          throw StateError('refund should not be called'),
      applyRequired: (_) async =>
          throw StateError('required should not be called'),
    );

    final result = await handler.handle(
      await _event(
        _payload(
          type: CallPaymentEventType.transfer,
          callType: CallPaymentCallType.video,
        ),
      ),
    );

    expect(result.handled, isTrue);
    expect(result.type, CallPaymentEventType.transfer);
    expect(receivedRequest?.owner, _owner);
    expect(receivedRequest?.senderPubkey, _senderPubkey);
    expect(receivedRequest?.callType, CallPaymentCallType.video);
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
      receiveRefund: (_) async =>
          throw StateError('refund should not be called'),
      applyRequired: (_) async =>
          throw StateError('required should not be called'),
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

  test('dispatches required payloads to required service', () async {
    CallPaymentRequiredRequest? receivedRequest;
    final handler = CallPaymentEventHandler(
      owner: _owner,
      receiveTransfer: (_) async =>
          throw StateError('transfer should not be called'),
      applyAck: (_) async => throw StateError('ack should not be called'),
      receiveRefund: (_) async =>
          throw StateError('refund should not be called'),
      applyRequired: (request) async {
        receivedRequest = request;
        return _requiredResult();
      },
    );

    final result = await handler.handle(
      await _event(_payload(type: CallPaymentEventType.required)),
    );

    expect(result.handled, isTrue);
    expect(result.type, CallPaymentEventType.required);
    expect(receivedRequest?.owner, _owner);
    expect(receivedRequest?.senderPubkey, _senderPubkey);
    expect(receivedRequest?.payload.type, CallPaymentEventType.required);
  });

  test('dispatches refund payloads to refund service', () async {
    CallPaymentRefundRequest? receivedRequest;
    final handler = CallPaymentEventHandler(
      owner: _owner,
      receiveTransfer: (_) async =>
          throw StateError('transfer should not be called'),
      applyAck: (_) async => throw StateError('ack should not be called'),
      receiveRefund: (request) async {
        receivedRequest = request;
        return _refundResult();
      },
      applyRequired: (_) async =>
          throw StateError('required should not be called'),
    );

    final result = await handler.handle(
      await _event(_payload(type: CallPaymentEventType.refund)),
    );

    expect(result.handled, isTrue);
    expect(result.type, CallPaymentEventType.refund);
    expect(receivedRequest?.owner, _owner);
    expect(receivedRequest?.senderPubkey, _senderPubkey);
    expect(receivedRequest?.payload.type, CallPaymentEventType.refund);
  });

  test('dispatches policy query events to policy query handler', () async {
    Event? queryEvent;
    final handler = CallPaymentEventHandler(
      owner: _owner,
      receiveTransfer: (_) async =>
          throw StateError('transfer should not be called'),
      applyAck: (_) async => throw StateError('ack should not be called'),
      receiveRefund: (_) async =>
          throw StateError('refund should not be called'),
      applyRequired: (_) async =>
          throw StateError('required should not be called'),
      handlePolicyQuery: (event) async {
        queryEvent = event;
      },
    );

    final event = await _policyEvent(
      CallPaymentPolicyEventPayload(
        type: CallPaymentPolicyEventType.query,
        requestId: 'policy-request-1',
        requesterPubkey: _senderPubkey,
        responderPubkey: _owner.value,
        createdAt: DateTime.utc(2026, 8, 14, 10),
      ),
    );

    final result = await handler.handle(event);

    expect(result.handled, isTrue);
    expect(result.type, CallPaymentPolicyEventType.query);
    expect(queryEvent?.id, event.id);
  });

  test(
    'ignores policy responses until a response waiter is configured',
    () async {
      final handler = CallPaymentEventHandler(
        owner: _owner,
        receiveTransfer: (_) async =>
            throw StateError('transfer should not be called'),
        applyAck: (_) async => throw StateError('ack should not be called'),
        receiveRefund: (_) async =>
            throw StateError('refund should not be called'),
        applyRequired: (_) async =>
            throw StateError('required should not be called'),
      );

      final result = await handler.handle(
        await _policyEvent(
          CallPaymentPolicyEventPayload(
            type: CallPaymentPolicyEventType.response,
            requestId: 'policy-request-1',
            requesterPubkey: _senderPubkey,
            responderPubkey: _owner.value,
            policy: _policy(),
            createdAt: DateTime.utc(2026, 8, 14, 10),
          ),
        ),
      );

      expect(result.handled, isFalse);
      expect(result.type, CallPaymentPolicyEventType.response);
      expect(result.ignoredReason, 'policy_response_waiter_not_configured');
    },
  );

  test(
    'ignores payment events when outer kind does not match payload type',
    () async {
      final handler = CallPaymentEventHandler(
        owner: _owner,
        receiveTransfer: (_) async =>
            throw StateError('transfer should not be called'),
        applyAck: (_) async => throw StateError('ack should not be called'),
        receiveRefund: (_) async =>
            throw StateError('refund should not be called'),
        applyRequired: (_) async =>
            throw StateError('required should not be called'),
      );

      final result = await handler.handle(
        await _event(
          _payload(type: CallPaymentEventType.ack),
          kind: CallPaymentEventType.transfer.kind,
        ),
      );

      expect(result.handled, isFalse);
      expect(result.type, CallPaymentEventType.ack);
      expect(result.ignoredReason, 'payment_event_kind_mismatch');
    },
  );
}

const _senderPrivkey =
    '0000000000000000000000000000000000000000000000000000000000000001';
const _senderPubkey =
    '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
final _owner = CashuAccountId.fromNostrPubkey('b' * 64);
final _mintUrl = CashuMintUrl.parse('https://mint.example');

Future<Event> _event(CallPaymentEventPayload payload, {int? kind}) {
  return Event.from(
    kind: kind ?? payload.type.kind,
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

Future<Event> _policyEvent(CallPaymentPolicyEventPayload payload) {
  return Event.from(
    kind: payload.type.kind,
    tags: [
      ['p', _owner.value],
      ['payment-policy-request-id', payload.requestId],
      ['payment-policy-type', payload.type.value],
    ],
    content: const CallPaymentPolicyEventCodec().encode(payload),
    pubkey: _senderPubkey,
    privkey: _senderPrivkey,
  );
}

CallPaymentEventPayload _payload({
  required CallPaymentEventType type,
  CallPaymentCallType callType = CallPaymentCallType.audio,
}) {
  return CallPaymentEventPayload(
    type: type,
    callId: 'call-1',
    paymentSessionId: 'payment-session-1',
    sequence: 1,
    purpose: CallPaymentPurpose.initial,
    callType: callType,
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
    token:
        type == CallPaymentEventType.transfer ||
            type == CallPaymentEventType.refund
        ? 'cashuAey'
        : null,
  );
}

CallPaymentPolicy _policy() {
  return CallPaymentPolicy(
    owner: _owner,
    enabled: true,
    freePolicy: CallPaymentFreePolicy.everyonePays,
    freePubkeys: const [],
    audioPriceSatsPerMinute: 10,
    videoPriceSatsPerMinute: 30,
    billingPeriodSeconds: 60,
    gracePeriodSeconds: 10,
    acceptedMintUrls: [_mintUrl],
    createdAt: DateTime.utc(2026, 8, 14, 9),
    updatedAt: DateTime.utc(2026, 8, 14, 9),
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

CallPaymentRefundResult _refundResult() {
  final now = DateTime.utc(2026, 8, 14, 10);
  return CallPaymentRefundResult(
    session: _session(now),
    installment: _installment(now, CallPaymentTransferDirection.received),
  );
}

CallPaymentRequiredResult _requiredResult() {
  final now = DateTime.utc(2026, 8, 14, 10);
  return CallPaymentRequiredResult(session: _session(now));
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
