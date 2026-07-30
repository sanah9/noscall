import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/core/common/network/connect_event_processor.dart';
import 'package:noscall/core/common/network/connect_request_tracker.dart';

void main() {
  test('skips cached events', () async {
    final tracker = ConnectRequestTracker();
    final processor = ConnectEventProcessor(
      isCached: (_) => true,
      isExpired: (_) => false,
      receiveEvent: (_, __) async {
        fail('cached events should not be received again');
      },
    );
    final event = Event.partial(id: 'event-1')..subscriptionId = 'sub-1';

    await processor.handle(
      event,
      'wss://relay.example.com',
      requestTracker: tracker,
    );

    expect(tracker.eventChecks, isEmpty);
  });

  test('receives expired events without tracking validation', () async {
    final tracker = ConnectRequestTracker();
    final received = <String>[];
    final processor = ConnectEventProcessor(
      isCached: (_) => false,
      isExpired: (_) => true,
      receiveEvent: (event, relay) async {
        received.add('$relay:${event.id}');
      },
    );
    final event = Event.partial(id: 'event-1')..subscriptionId = 'sub-1';

    await processor.handle(
      event,
      'wss://relay.example.com',
      requestTracker: tracker,
    );

    expect(received, equals(['wss://relay.example.com:event-1']));
    expect(tracker.eventChecks, isEmpty);
  });

  test('tracks validation future for subscribed active events', () async {
    final tracker = ConnectRequestTracker();
    final processor = ConnectEventProcessor(
      isCached: (_) => false,
      isExpired: (_) => false,
      receiveEvent: (_, __) async {},
    );
    late String subscriptionId;
    const relay = 'wss://relay.example.com';
    tracker.addSubscriptions(
      {
        relay: [
          Filter(kinds: [9999]),
        ],
      },
      onSubscription: (requestId, _, __) {
        subscriptionId = requestId;
      },
    );
    final event = Event.partial(id: 'event-1', kind: 9999)
      ..subscriptionId = subscriptionId;

    await processor.handle(event, relay, requestTracker: tracker);

    expect(tracker.eventChecks['$subscriptionId$relay'], hasLength(1));
  });
}
