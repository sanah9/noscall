import 'dart:async';

import 'package:nostr_core_dart/nostr.dart';

import 'package:noscall/core/call/nip_ac_protocol.dart';
import 'package:noscall/core/common/network/connect.dart';

import '../application/call_payment_initial_payment_service.dart';
import 'call_payment_event_codec.dart';
import 'call_payment_policy_event_codec.dart';

abstract interface class CallPaymentRelaySender {
  void send(
    Event event, {
    required OKCallBack sendCallBack,
    List<RelayKind> relayKinds = const [RelayKind.general],
  });
}

final class ConnectCallPaymentRelaySender implements CallPaymentRelaySender {
  const ConnectCallPaymentRelaySender();

  @override
  void send(
    Event event, {
    required OKCallBack sendCallBack,
    List<RelayKind> relayKinds = const [RelayKind.general],
  }) {
    Connect.sharedInstance.sendEvent(
      event,
      sendCallBack: sendCallBack,
      relayKinds: relayKinds,
    );
  }
}

final class CallPaymentNostrGateway implements CallPaymentTransferGateway {
  CallPaymentNostrGateway({
    required String pubkey,
    required String privkey,
    CallPaymentEventCodec codec = const CallPaymentEventCodec(),
    CallPaymentPolicyEventCodec policyCodec =
        const CallPaymentPolicyEventCodec(),
    CallPaymentRelaySender relaySender = const ConnectCallPaymentRelaySender(),
    Duration sendTimeout = const Duration(seconds: 10),
  }) : _pubkey = pubkey,
       _privkey = privkey,
       _codec = codec,
       _policyCodec = policyCodec,
       _relaySender = relaySender,
       _sendTimeout = sendTimeout;

  static const _alt = 'NIP-AC call payment';

  final String _pubkey;
  final String _privkey;
  final CallPaymentEventCodec _codec;
  final CallPaymentPolicyEventCodec _policyCodec;
  final CallPaymentRelaySender _relaySender;
  final Duration _sendTimeout;

  Future<Event> createInnerEvent({
    required String receiverPubkey,
    required CallPaymentEventPayload payload,
  }) {
    return Event.from(
      kind: payload.type.kind,
      tags: [
        ['p', receiverPubkey],
        ['call-id', payload.callId],
        ['payment-session-id', payload.paymentSessionId],
        ['payment-type', payload.type.value],
        ['alt', _alt],
      ],
      content: _codec.encode(payload),
      pubkey: _pubkey,
      privkey: _privkey,
    );
  }

  Future<Event> createPolicyInnerEvent({
    required String receiverPubkey,
    required CallPaymentPolicyEventPayload payload,
  }) {
    return Event.from(
      kind: payload.type.kind,
      tags: [
        ['p', receiverPubkey],
        ['payment-policy-request-id', payload.requestId],
        ['payment-policy-type', payload.type.value],
        ['alt', _alt],
      ],
      content: _policyCodec.encode(payload),
      pubkey: _pubkey,
      privkey: _privkey,
    );
  }

  @override
  Future<OKEvent> send({
    required String receiverPubkey,
    required CallPaymentEventPayload payload,
  }) async {
    final innerEvent = await createInnerEvent(
      receiverPubkey: receiverPubkey,
      payload: payload,
    );
    final wrapped = await NipAcProtocol.wrap(innerEvent, receiverPubkey);
    final completer = Completer<OKEvent>();
    _relaySender.send(
      wrapped,
      relayKinds: const [RelayKind.general],
      sendCallBack: (ok, relay) {
        if (!completer.isCompleted) {
          completer.complete(OKEvent(innerEvent.id, ok.status, ok.message));
        }
      },
    );
    return completer.future.timeout(
      _sendTimeout,
      onTimeout: () =>
          OKEvent(innerEvent.id, false, 'payment event send timeout'),
    );
  }

  Future<OKEvent> sendPolicyEvent({
    required String receiverPubkey,
    required CallPaymentPolicyEventPayload payload,
  }) async {
    final innerEvent = await createPolicyInnerEvent(
      receiverPubkey: receiverPubkey,
      payload: payload,
    );
    final wrapped = await NipAcProtocol.wrap(
      innerEvent,
      receiverPubkey,
      includeKindMarker: true,
    );
    final completer = Completer<OKEvent>();
    _relaySender.send(
      wrapped,
      relayKinds: const [RelayKind.general],
      sendCallBack: (ok, relay) {
        if (!completer.isCompleted) {
          completer.complete(OKEvent(innerEvent.id, ok.status, ok.message));
        }
      },
    );
    return completer.future.timeout(
      _sendTimeout,
      onTimeout: () =>
          OKEvent(innerEvent.id, false, 'policy event send timeout'),
    );
  }
}
