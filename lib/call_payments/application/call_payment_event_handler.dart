import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';

import '../domain/call_payment_models.dart';
import 'call_payment_ack_service.dart';
import 'call_payment_incoming_transfer_service.dart';

typedef CallPaymentIncomingTransferCallback =
    Future<CallPaymentIncomingTransferResult> Function(
      CallPaymentIncomingTransferRequest request,
    );
typedef CallPaymentAckCallback =
    Future<CallPaymentAckResult> Function(CallPaymentAckRequest request);
typedef CallPaymentEventCallTypeResolver =
    CallPaymentCallType Function(Event event, CallPaymentEventPayload payload);

final class CallPaymentEventHandleResult {
  const CallPaymentEventHandleResult.handled(this.type)
    : handled = true,
      ignoredReason = null;

  const CallPaymentEventHandleResult.ignored(this.type, this.ignoredReason)
    : handled = false;

  final bool handled;
  final CallPaymentEventType type;
  final String? ignoredReason;
}

final class CallPaymentEventHandler {
  CallPaymentEventHandler({
    required CashuAccountId owner,
    required CallPaymentIncomingTransferCallback receiveTransfer,
    required CallPaymentAckCallback applyAck,
    required CallPaymentEventCallTypeResolver resolveCallType,
    CallPaymentEventCodec codec = const CallPaymentEventCodec(),
  }) : _owner = owner,
       _receiveTransfer = receiveTransfer,
       _applyAck = applyAck,
       _resolveCallType = resolveCallType,
       _codec = codec;

  final CashuAccountId _owner;
  final CallPaymentIncomingTransferCallback _receiveTransfer;
  final CallPaymentAckCallback _applyAck;
  final CallPaymentEventCallTypeResolver _resolveCallType;
  final CallPaymentEventCodec _codec;

  Future<CallPaymentEventHandleResult> handle(Event event) async {
    final payload = _codec.decode(event.content);
    switch (payload.type) {
      case CallPaymentEventType.transfer:
        await _receiveTransfer(
          CallPaymentIncomingTransferRequest(
            owner: _owner,
            senderPubkey: event.pubkey,
            callType: _resolveCallType(event, payload),
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
      case CallPaymentEventType.required:
      case CallPaymentEventType.refund:
        return CallPaymentEventHandleResult.ignored(
          payload.type,
          'payment_event_type_not_supported_yet',
        );
    }
  }
}
