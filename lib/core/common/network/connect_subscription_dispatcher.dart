import 'package:nostr_core_dart/nostr.dart';

import 'connect_request_tracker.dart';
import 'connect_subscription_queue.dart';
import 'connect_types.dart';

typedef ConnectSubscriptionSend =
    void Function(String data, List<String> relays);

class ConnectSubscriptionDispatcher {
  ConnectSubscriptionDispatcher({
    required ConnectRequestTracker requestTracker,
    required ConnectSubscriptionQueue subscriptionQueue,
  }) : _requestTracker = requestTracker,
       _subscriptionQueue = subscriptionQueue;

  final ConnectRequestTracker _requestTracker;
  final ConnectSubscriptionQueue _subscriptionQueue;

  void enqueue(
    String subscriptionId,
    String relay, {
    required Map<String, Requests> requestsMap,
    required ConnectSubscriptionSend send,
    void Function(int sendingQueue, int waitingQueue, String relay)? onIdle,
  }) {
    _subscriptionQueue.add(subscriptionId, relay);
    sendNext(relay, requestsMap: requestsMap, send: send, onIdle: onIdle);
  }

  void sendNext(
    String relay, {
    required Map<String, Requests> requestsMap,
    required ConnectSubscriptionSend send,
    void Function(int sendingQueue, int waitingQueue, String relay)? onIdle,
  }) {
    final subscriptionId = _subscriptionQueue.takeNext(relay, requestsMap);
    if (subscriptionId != null) {
      final request = _requestTracker.markSubscriptionSent(
        subscriptionId,
        relay,
      );
      if (request != null) {
        send(request.subscriptionString, [relay]);
      }
      return;
    }

    onIdle?.call(
      _subscriptionQueue.activeCount(relay, requestsMap),
      _subscriptionQueue.waitingCount(relay),
      relay,
    );
  }

  void close(
    String subscriptionId,
    String relay, {
    required Map<String, Requests> requestsMap,
    required ConnectSubscriptionSend send,
    void Function(int sendingQueue, int waitingQueue, String relay)? onIdle,
  }) {
    if (subscriptionId.isEmpty) return;
    send(Close(subscriptionId).serialize(), [relay]);
    _requestTracker.removeSubscription(subscriptionId, relay);
    sendNext(relay, requestsMap: requestsMap, send: send, onIdle: onIdle);
  }
}
