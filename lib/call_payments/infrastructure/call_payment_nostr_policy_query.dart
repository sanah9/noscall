import 'dart:async';

import 'package:nostr_core_dart/nostr.dart';
import 'package:uuid/uuid.dart';

import 'package:noscall/core/call/nip_ac_protocol.dart';
import 'package:noscall/core/common/network/connect.dart';

import '../domain/call_payment_models.dart';
import 'call_payment_nostr_gateway.dart';
import 'call_payment_policy_event_codec.dart';

typedef CallPaymentPolicyRequestIdFactory = String Function();
typedef CallPaymentWrappedEventCallback =
    FutureOr<void> Function(Event event, String relay);

abstract interface class CallPaymentPolicyResponseSubscriber {
  String subscribe({
    required String receiverPubkey,
    required int since,
    required CallPaymentWrappedEventCallback onEvent,
  });

  Future<void> close(String subscriptionId);
}

final class ConnectCallPaymentPolicyResponseSubscriber
    implements CallPaymentPolicyResponseSubscriber {
  const ConnectCallPaymentPolicyResponseSubscriber();

  @override
  String subscribe({
    required String receiverPubkey,
    required int since,
    required CallPaymentWrappedEventCallback onEvent,
  }) {
    return Connect.sharedInstance.addSubscription(
      [
        Filter(
          kinds: const [NipAcProtocol.wrapKind],
          p: [receiverPubkey],
          since: since,
          limit: 50,
        ),
      ],
      closeSubscription: false,
      relayKinds: const [RelayKind.general],
      eventCallBack: (event, relay) async {
        await onEvent(event, relay);
      },
    );
  }

  @override
  Future<void> close(String subscriptionId) {
    if (subscriptionId.isEmpty) return Future.value();
    return Connect.sharedInstance.closeRequests(subscriptionId);
  }
}

final class CallPaymentNostrPolicyQuery {
  CallPaymentNostrPolicyQuery({
    required String pubkey,
    required String privkey,
    required CallPaymentNostrGateway gateway,
    CallPaymentPolicyResponseSubscriber subscriber =
        const ConnectCallPaymentPolicyResponseSubscriber(),
    CallPaymentPolicyEventCodec codec = const CallPaymentPolicyEventCodec(),
    CallPaymentPolicyRequestIdFactory requestIdFactory =
        _defaultRequestIdFactory,
    DateTime Function()? clock,
    Duration timeout = const Duration(seconds: 10),
  }) : _pubkey = pubkey,
       _privkey = privkey,
       _gateway = gateway,
       _subscriber = subscriber,
       _codec = codec,
       _requestIdFactory = requestIdFactory,
       _clock = clock ?? DateTime.now,
       _timeout = timeout;

  final String _pubkey;
  final String _privkey;
  final CallPaymentNostrGateway _gateway;
  final CallPaymentPolicyResponseSubscriber _subscriber;
  final CallPaymentPolicyEventCodec _codec;
  final CallPaymentPolicyRequestIdFactory _requestIdFactory;
  final DateTime Function() _clock;
  final Duration _timeout;

  Future<CallPaymentPolicy?> query(String peerPubkey) async {
    final requestId = _requestIdFactory();
    final completer = Completer<CallPaymentPolicy?>();
    late final String subscriptionId;

    subscriptionId = _subscriber.subscribe(
      receiverPubkey: _pubkey,
      since: _clock().toUtc().millisecondsSinceEpoch ~/ 1000 - 5,
      onEvent: (event, relay) async {
        if (completer.isCompleted) return;
        final policy = await _tryReadPolicyResponse(
          event: event,
          peerPubkey: peerPubkey,
          requestId: requestId,
        );
        if (policy != null) {
          completer.complete(policy);
        }
      },
    );

    if (subscriptionId.isEmpty) return null;

    try {
      final ok = await _gateway.sendPolicyEvent(
        receiverPubkey: peerPubkey,
        payload: CallPaymentPolicyEventPayload(
          type: CallPaymentPolicyEventType.query,
          requestId: requestId,
          requesterPubkey: _pubkey,
          responderPubkey: peerPubkey,
          createdAt: _clock(),
        ),
      );
      if (!ok.status && !completer.isCompleted) {
        completer.complete(null);
      }

      return await completer.future.timeout(_timeout, onTimeout: () => null);
    } finally {
      await _subscriber.close(subscriptionId);
    }
  }

  Future<CallPaymentPolicy?> _tryReadPolicyResponse({
    required Event event,
    required String peerPubkey,
    required String requestId,
  }) async {
    try {
      if (event.kind != NipAcProtocol.wrapKind) return null;
      final innerEvent = await NipAcProtocol.tryUnwrap(
        event,
        _pubkey,
        _privkey,
      );
      if (innerEvent == null ||
          innerEvent.kind != CallPaymentPolicyEventType.response.kind ||
          innerEvent.pubkey != peerPubkey) {
        return null;
      }

      final payload = _codec.decode(innerEvent.content);
      if (payload.type != CallPaymentPolicyEventType.response ||
          payload.requestId != requestId ||
          payload.requesterPubkey != _pubkey ||
          payload.responderPubkey != peerPubkey ||
          payload.policy?.owner.value != peerPubkey ||
          !_matchesPolicyResponseTags(innerEvent, payload)) {
        return null;
      }
      return payload.policy;
    } catch (_) {
      return null;
    }
  }

  bool _matchesPolicyResponseTags(
    Event event,
    CallPaymentPolicyEventPayload payload,
  ) {
    return _hasTag(event, 'p', payload.requesterPubkey) &&
        _hasTag(event, 'payment-policy-request-id', payload.requestId) &&
        _hasTag(event, 'payment-policy-type', payload.type.value);
  }

  bool _hasTag(Event event, String name, String value) {
    return event.tags.any(
      (tag) => tag.length >= 2 && tag[0] == name && tag[1] == value,
    );
  }
}

String _defaultRequestIdFactory() => const Uuid().v4();
