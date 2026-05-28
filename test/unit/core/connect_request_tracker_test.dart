import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/core/common/network/connect_request_tracker.dart';

void main() {
  group('ConnectRequestTracker', () {
    test('addSubscriptions tracks requests and emits queue work', () {
      final tracker = ConnectRequestTracker();
      final queued = <({String requestId, String relay, String data})>[];

      final requestId = tracker.addSubscriptions(
        {
          'wss://relay-1.example.com': [
            Filter(kinds: [1])
          ],
          'wss://relay-2.example.com': [
            Filter(kinds: [1])
          ],
        },
        onSubscription: (requestId, relay, subscriptionString) {
          queued.add((
            requestId: requestId,
            relay: relay,
            data: subscriptionString,
          ));
        },
      );

      expect(queued, hasLength(2));
      expect(
        queued.map((item) => item.relay),
        containsAll(['wss://relay-1.example.com', 'wss://relay-2.example.com']),
      );
      expect(
        tracker.requestFor(requestId, 'wss://relay-1.example.com'),
        isNotNull,
      );
      expect(
        tracker.requestFor(requestId, 'wss://relay-2.example.com'),
        isNotNull,
      );
    });

    test('markSubscriptionSent updates request time', () {
      final tracker = ConnectRequestTracker();
      final requestId = tracker.addSubscriptions(
        {
          'wss://relay.example.com': [
            Filter(kinds: [1])
          ],
        },
        onSubscription: (_, __, ___) {},
      );

      final request = tracker.markSubscriptionSent(
        requestId,
        'wss://relay.example.com',
        now: DateTime.fromMillisecondsSinceEpoch(1234),
      );

      expect(request?.requestTime, 1234);
      expect(
        tracker.requestFor(requestId, 'wss://relay.example.com')?.requestTime,
        1234,
      );
    });

    test('completeRelay removes relay from sibling requests and calls eose',
        () {
      final tracker = ConnectRequestTracker();
      final callbacks = <String>[];
      final requestId = tracker.addSubscriptions(
        {
          'wss://relay-1.example.com': [
            Filter(kinds: [1])
          ],
          'wss://relay-2.example.com': [
            Filter(kinds: [1])
          ],
        },
        eoseCallBack: (requestId, ok, relay, uncompletedRelays) {
          callbacks.add('$relay:${ok.status}:${uncompletedRelays.join(',')}');
        },
        onSubscription: (_, __, ___) {},
      );

      final shouldClose = tracker.completeRelay(
        requestId,
        'wss://relay-1.example.com',
        false,
      );

      expect(shouldClose, isTrue);
      expect(callbacks,
          ['wss://relay-1.example.com:true:wss://relay-2.example.com']);
      expect(
        tracker.requestFor(requestId, 'wss://relay-2.example.com')?.relays,
        ['wss://relay-2.example.com'],
      );
    });

    test('waitForEventChecks waits and clears tracked futures', () async {
      final tracker = ConnectRequestTracker();

      tracker.trackEventCheck(
        'subscription-id',
        'wss://relay.example.com',
        Future.value(true),
      );

      await tracker.waitForEventChecks(
        'subscription-id',
        'wss://relay.example.com',
      );

      expect(tracker.eventChecks, isEmpty);
    });

    test('closeTargets returns relay-specific subscription target', () {
      final tracker = ConnectRequestTracker();
      final requestId = tracker.addSubscriptions(
        {
          'wss://relay.example.com': [
            Filter(kinds: [1])
          ],
        },
        onSubscription: (_, __, ___) {},
      );

      final targets = tracker.closeTargets(
        requestId,
        relay: 'wss://relay.example.com',
        connectedRelays: const [],
      );

      expect(targets, hasLength(1));
      expect(targets.single.subscriptionId, requestId);
      expect(targets.single.relay, 'wss://relay.example.com');
    });
  });
}
