import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/core/common/network/connect_auth_state.dart';
import 'package:noscall/core/common/network/connect_request_completion_handler.dart';
import 'package:noscall/core/common/network/connect_request_tracker.dart';

Auth authChallenge(String challenge) {
  return Auth.deserialize(['AUTH', challenge]);
}

void main() {
  test(
    'handleEose waits for event checks and closes completed subscription',
    () async {
      final tracker = ConnectRequestTracker();
      final handler = _handlerFor(tracker);
      final closed = <String>[];
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
      tracker.trackEventCheck(subscriptionId, relay, Future.value(true));

      await handler.handleEose(
        '["$subscriptionId"]',
        relay,
        false,
        closeSubscription: (subscriptionId, relay) {
          closed.add('$relay:$subscriptionId');
        },
      );

      expect(closed, equals(['$relay:$subscriptionId']));
      expect(tracker.eventChecks, isEmpty);
    },
  );

  test(
    'handleClosed queues auth resend and sends auth when auth is required',
    () async {
      final tracker = ConnectRequestTracker();
      final authState = ConnectAuthState();
      final handler = _handlerFor(tracker, authState: authState);
      final authRelays = <String>[];
      const relay = 'wss://relay.example.com';
      late String subscriptionId;
      late String subscriptionString;

      authState.registerChallenge(authChallenge('challenge-1'), relay);
      tracker.addSubscriptions(
        {
          relay: [
            Filter(kinds: [1]),
          ],
        },
        onSubscription: (requestId, _, data) {
          subscriptionId = requestId;
          subscriptionString = data;
        },
      );

      await handler.handleClosed(
        Closed.deserialize([
          'CLOSED',
          subscriptionId,
          'auth-required: sign in',
        ]),
        relay,
        closeSubscription: (_, __) {
          fail('auth-required closed messages should not close immediately');
        },
        sendAuth: authRelays.add,
      );

      expect(authRelays, equals([relay]));
      expect(authState.auths[relay]?.resendDatas, equals([subscriptionString]));
    },
  );

  test(
    'handleNotice completes all subscriptions for relay and calls callback',
    () async {
      final tracker = ConnectRequestTracker();
      final handler = _handlerFor(tracker);
      final closed = <String>[];
      final notices = <String>[];
      const relay = 'wss://relay.example.com';

      tracker.addSubscriptions({
        relay: [
          Filter(kinds: [1]),
        ],
      }, onSubscription: (_, __, ___) {});
      tracker.addSubscriptions({
        relay: [
          Filter(kinds: [2]),
        ],
      }, onSubscription: (_, __, ___) {});

      await handler.handleNotice(
        '["restricted"]',
        relay,
        noticeCallBack: (notice, relay) {
          notices.add('$relay:$notice');
        },
        closeSubscription: (subscriptionId, relay) {
          closed.add('$relay:$subscriptionId');
        },
      );

      expect(notices, equals(['$relay:restricted']));
      expect(closed, hasLength(2));
    },
  );
}

ConnectRequestCompletionHandler _handlerFor(
  ConnectRequestTracker tracker, {
  ConnectAuthState? authState,
}) {
  return ConnectRequestCompletionHandler(
    requestTracker: tracker,
    authState: authState ?? ConnectAuthState(),
  );
}
