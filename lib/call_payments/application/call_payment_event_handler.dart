import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_policy_event_codec.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';

import '../domain/call_payment_models.dart';
import 'call_payment_ack_service.dart';
import 'call_payment_incoming_transfer_service.dart';
import 'call_payment_refund_service.dart';
import 'call_payment_required_service.dart';

typedef CallPaymentIncomingTransferCallback =
    Future<CallPaymentIncomingTransferResult> Function(
      CallPaymentIncomingTransferRequest request,
    );
typedef CallPaymentAckCallback =
    Future<CallPaymentAckResult> Function(CallPaymentAckRequest request);
typedef CallPaymentRefundCallback =
    Future<CallPaymentRefundResult> Function(CallPaymentRefundRequest request);
typedef CallPaymentRequiredCallback =
    Future<CallPaymentRequiredResult> Function(
      CallPaymentRequiredRequest request,
    );
typedef CallPaymentEventCallTypeResolver =
    CallPaymentCallType Function(Event event, CallPaymentEventPayload payload);
typedef CallPaymentPolicyQueryCallback = Future<void> Function(Event event);

final class CallPaymentEventHandleResult {
  const CallPaymentEventHandleResult.handled(this.type)
    : handled = true,
      ignoredReason = null;

  const CallPaymentEventHandleResult.ignored(this.type, this.ignoredReason)
    : handled = false;

  final bool handled;
  final Object type;
  final String? ignoredReason;
}

final class CallPaymentEventHandler {
  CallPaymentEventHandler({
    required CashuAccountId owner,
    required CallPaymentIncomingTransferCallback receiveTransfer,
    required CallPaymentAckCallback applyAck,
    required CallPaymentRefundCallback receiveRefund,
    required CallPaymentRequiredCallback applyRequired,
    CallPaymentPolicyQueryCallback? handlePolicyQuery,
    CallPaymentEventCallTypeResolver? resolveCallType,
    CallPaymentEventCodec codec = const CallPaymentEventCodec(),
  }) : _owner = owner,
       _receiveTransfer = receiveTransfer,
       _applyAck = applyAck,
       _receiveRefund = receiveRefund,
       _applyRequired = applyRequired,
       _handlePolicyQuery = handlePolicyQuery,
       _resolveCallType = resolveCallType,
       _codec = codec;

  final CashuAccountId _owner;
  final CallPaymentIncomingTransferCallback _receiveTransfer;
  final CallPaymentAckCallback _applyAck;
  final CallPaymentRefundCallback _receiveRefund;
  final CallPaymentRequiredCallback _applyRequired;
  final CallPaymentPolicyQueryCallback? _handlePolicyQuery;
  final CallPaymentEventCallTypeResolver? _resolveCallType;
  final CallPaymentEventCodec _codec;

  Future<CallPaymentEventHandleResult> handle(Event event) async {
    if (event.kind == CallPaymentPolicyEventType.query.kind) {
      final handler = _handlePolicyQuery;
      if (handler == null) {
        return const CallPaymentEventHandleResult.ignored(
          CallPaymentPolicyEventType.query,
          'policy_query_handler_not_configured',
        );
      }
      await handler(event);
      return const CallPaymentEventHandleResult.handled(
        CallPaymentPolicyEventType.query,
      );
    }
    if (event.kind == CallPaymentPolicyEventType.response.kind) {
      return const CallPaymentEventHandleResult.ignored(
        CallPaymentPolicyEventType.response,
        'policy_response_waiter_not_configured',
      );
    }

    final payload = _codec.decode(event.content);
    if (event.kind != payload.type.kind) {
      return CallPaymentEventHandleResult.ignored(
        payload.type,
        'payment_event_kind_mismatch',
      );
    }
    switch (payload.type) {
      case CallPaymentEventType.transfer:
        await _receiveTransfer(
          CallPaymentIncomingTransferRequest(
            owner: _owner,
            senderPubkey: event.pubkey,
            callType:
                _resolveCallType?.call(event, payload) ?? payload.callType,
            payload: payload,
          ),
        );
        return CallPaymentEventHandleResult.handled(payload.type);
      case CallPaymentEventType.ack:
        await _applyAck(
          CallPaymentAckRequest(
            owner: _owner,
            senderPubkey: event.pubkey,
            payload: payload,
          ),
        );
        return CallPaymentEventHandleResult.handled(payload.type);
      case CallPaymentEventType.refund:
        await _receiveRefund(
          CallPaymentRefundRequest(
            owner: _owner,
            senderPubkey: event.pubkey,
            payload: payload,
          ),
        );
        return CallPaymentEventHandleResult.handled(payload.type);
      case CallPaymentEventType.required:
        await _applyRequired(
          CallPaymentRequiredRequest(
            owner: _owner,
            senderPubkey: event.pubkey,
            payload: payload,
          ),
        );
        return CallPaymentEventHandleResult.handled(payload.type);
    }
  }
}
