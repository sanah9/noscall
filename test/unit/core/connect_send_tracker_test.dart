import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/core/common/network/connect_send_tracker.dart';

void main() {
  group('ConnectSendTracker', () {
    test('trackEvent stores a pending send with a copied relay list', () {
      final tracker = ConnectSendTracker();
      final relays = ['wss://relay-1.example.com'];

      tracker.trackEvent(
        eventId: 'event-1',
        eventString: '["EVENT",{}]',
        relays: relays,
        now: DateTime.fromMillisecondsSinceEpoch(1234),
      );
      relays.add('wss://relay-2.example.com');

      final send = tracker.sends['event-1'];
      expect(send, isNotNull);
      expect(send?.relays, ['wss://relay-1.example.com']);
      expect(send?.sendsTime, 1234);
    });

    test('handleOk invokes callback and clears send on success', () {
      final tracker = ConnectSendTracker();
      OKEvent? receivedOk;
      String? receivedRelay;

      tracker.trackEvent(
        eventId: 'event-1',
        eventString: '["EVENT",{}]',
        relays: ['wss://relay-1.example.com'],
        okCallBack: (ok, relay) {
          receivedOk = ok;
          receivedRelay = relay;
        },
      );

      final result = tracker.handleOk(
        OKEvent('event-1', true, ''),
        'wss://relay-1.example.com',
      );

      expect(result.authRequiredEventString, isNull);
      expect(result.failedRelayForRequests, isNull);
      expect(receivedOk?.status, isTrue);
      expect(receivedRelay, 'wss://relay-1.example.com');
      expect(tracker.sends.containsKey('event-1'), isFalse);
    });

    test('handleOk waits for remaining relays before failed callback', () {
      final tracker = ConnectSendTracker();
      final callbacks = <String>[];

      tracker.trackEvent(
        eventId: 'event-1',
        eventString: '["EVENT",{}]',
        relays: ['wss://relay-1.example.com', 'wss://relay-2.example.com'],
        okCallBack: (ok, relay) {
          callbacks.add('$relay:${ok.status}');
        },
      );

      tracker.handleOk(
        OKEvent('event-1', false, 'rejected'),
        'wss://relay-1.example.com',
      );

      expect(callbacks, isEmpty);
      expect(tracker.sends.containsKey('event-1'), isTrue);

      tracker.handleOk(
        OKEvent('event-1', false, 'rejected'),
        'wss://relay-2.example.com',
      );

      expect(callbacks, ['wss://relay-2.example.com:false']);
      expect(tracker.sends.containsKey('event-1'), isFalse);
    });

    test('handleOk returns event string when relay requires auth', () {
      final tracker = ConnectSendTracker();

      tracker.trackEvent(
        eventId: 'event-1',
        eventString: '["EVENT",{}]',
        relays: ['wss://relay-1.example.com'],
      );

      final result = tracker.handleOk(
        OKEvent('event-1', false, 'auth-required: sign in first'),
        'wss://relay-1.example.com',
      );

      expect(result.authRequiredEventString, '["EVENT",{}]');
      expect(tracker.sends.containsKey('event-1'), isTrue);
    });
  });
}
