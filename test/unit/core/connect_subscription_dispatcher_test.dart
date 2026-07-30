import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/core/common/network/connect_request_tracker.dart';
import 'package:noscall/core/common/network/connect_subscription_dispatcher.dart';
import 'package:noscall/core/common/network/connect_subscription_queue.dart';

void main() {
  test('enqueue sends the next waiting subscription', () {
    final tracker = ConnectRequestTracker();
    final queue = ConnectSubscriptionQueue(maxInFlight: 2);
    final dispatcher = ConnectSubscriptionDispatcher(
      requestTracker: tracker,
      subscriptionQueue: queue,
    );
    final sent = <String>[];
    late String subscriptionId;
    const relay = 'wss://relay.example.com';

    tracker.addSubscriptions(
      {
        relay: [
          Filter(kinds: [1]),
        ],
      },
      onSubscription: (requestId, _, __) {
        subscriptionId = requestId;
      },
    );

    dispatcher.enqueue(
      subscriptionId,
      relay,
      requestsMap: tracker.requests,
      send: (data, relays) {
        sent.add('${relays.single}:$data');
      },
    );

    expect(sent, hasLength(1));
    expect(sent.single, startsWith('$relay:["REQ"'));
    expect(tracker.requestFor(subscriptionId, relay)?.requestTime, isPositive);
    expect(queue.waitingCount(relay), 0);
  });

  test('enqueue reports queue state when relay is at capacity', () {
    final tracker = ConnectRequestTracker();
    final queue = ConnectSubscriptionQueue(maxInFlight: 1);
    final dispatcher = ConnectSubscriptionDispatcher(
      requestTracker: tracker,
      subscriptionQueue: queue,
    );
    final idleStates = <String>[];
    const relay = 'wss://relay.example.com';
    final subscriptionIds = <String>[];

    tracker.addSubscriptions(
      {
        relay: [
          Filter(kinds: [1]),
        ],
      },
      onSubscription: (requestId, _, __) {
        subscriptionIds.add(requestId);
      },
    );
    tracker.addSubscriptions(
      {
        relay: [
          Filter(kinds: [2]),
        ],
      },
      onSubscription: (requestId, _, __) {
        subscriptionIds.add(requestId);
      },
    );

    dispatcher.enqueue(
      subscriptionIds.first,
      relay,
      requestsMap: tracker.requests,
      send: (_, __) {},
    );
    dispatcher.enqueue(
      subscriptionIds.last,
      relay,
      requestsMap: tracker.requests,
      send: (_, __) {},
      onIdle: (sendingQueue, waitingQueue, relay) {
        idleStates.add('$relay:$sendingQueue:$waitingQueue');
      },
    );

    expect(idleStates, equals(['$relay:1:1']));
  });

  test('close removes subscription and sends next waiting item', () {
    final tracker = ConnectRequestTracker();
    final queue = ConnectSubscriptionQueue(maxInFlight: 1);
    final dispatcher = ConnectSubscriptionDispatcher(
      requestTracker: tracker,
      subscriptionQueue: queue,
    );
    final sent = <String>[];
    const relay = 'wss://relay.example.com';
    final subscriptionIds = <String>[];

    tracker.addSubscriptions(
      {
        relay: [
          Filter(kinds: [1]),
        ],
      },
      onSubscription: (requestId, _, __) {
        subscriptionIds.add(requestId);
      },
    );
    tracker.addSubscriptions(
      {
        relay: [
          Filter(kinds: [2]),
        ],
      },
      onSubscription: (requestId, _, __) {
        subscriptionIds.add(requestId);
      },
    );

    dispatcher.enqueue(
      subscriptionIds.first,
      relay,
      requestsMap: tracker.requests,
      send: (data, _) {
        sent.add(data);
      },
    );
    dispatcher.enqueue(
      subscriptionIds.last,
      relay,
      requestsMap: tracker.requests,
      send: (data, _) {
        sent.add(data);
      },
    );

    dispatcher.close(
      subscriptionIds.first,
      relay,
      requestsMap: tracker.requests,
      send: (data, _) {
        sent.add(data);
      },
    );

    expect(sent[1], equals(Close(subscriptionIds.first).serialize()));
    expect(sent[2], startsWith('["REQ"'));
    expect(tracker.requestFor(subscriptionIds.first, relay), isNull);
    expect(
      tracker.requestFor(subscriptionIds.last, relay)?.requestTime,
      isPositive,
    );
  });
}
