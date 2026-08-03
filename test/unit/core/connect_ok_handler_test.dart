import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/core/common/network/connect_auth_state.dart';
import 'package:noscall/core/common/network/connect_ok_handler.dart';
import 'package:noscall/core/common/network/connect_send_tracker.dart';

Auth authChallenge(String challenge) {
  return Auth.deserialize(['AUTH', challenge]);
}

void main() {
  test('successful auth response resends queued data to the relay', () async {
    final authState = ConnectAuthState();
    final handler = _handlerFor(authState: authState);
    final sent = <String>[];
    const relay = 'wss://relay.example.com';

    authState.registerChallenge(authChallenge('challenge-1'), relay);
    authState.queueResend(relay, '["REQ","sub-1",{}]');
    authState.markSending(relay);
    authState.markSent(relay, 'auth-event-id');

    await handler.handle(
      OKEvent('auth-event-id', true, ''),
      relay,
      send: (data, relays) {
        sent.add('${relays.join(',')}:$data');
      },
      sendAuth: (_) {
        fail('auth OK should not send another auth event');
      },
      completeRelayRequests: (_) {
        fail('auth OK should not complete relay requests');
      },
    );

    expect(sent, equals(['$relay:["REQ","sub-1",{}]']));
    expect(authState.auths.containsKey(relay), isFalse);
  });

  test('auth-required OK queues event resend and sends auth', () async {
    final authState = ConnectAuthState();
    final sendTracker = ConnectSendTracker();
    final handler = _handlerFor(authState: authState, sendTracker: sendTracker);
    final authRelays = <String>[];
    const relay = 'wss://relay.example.com';
    const eventString = '["EVENT",{}]';

    authState.registerChallenge(authChallenge('challenge-1'), relay);
    sendTracker.trackEvent(
      eventId: 'event-1',
      eventString: eventString,
      relays: [relay],
    );

    await handler.handle(
      OKEvent('event-1', false, 'auth-required: sign in'),
      relay,
      send: (_, __) {
        fail('auth-required OK should not resend before auth succeeds');
      },
      sendAuth: authRelays.add,
      completeRelayRequests: (_) {
        fail('auth-required OK should not complete relay requests');
      },
    );

    expect(authRelays, equals([relay]));
    expect(authState.auths[relay]?.resendDatas, equals([eventString]));
  });

  test(
    'failed relay result completes pending requests for that relay',
    () async {
      final sendTracker = ConnectSendTracker();
      final handler = _handlerFor(sendTracker: sendTracker);
      final completedRelays = <String>[];
      const relay = 'wss://relay.example.com';

      sendTracker.trackEvent(
        eventId: '',
        eventString: '["EVENT",{}]',
        relays: [relay, 'wss://relay-2.example.com'],
        okCallBack: (_, __) {},
      );

      await handler.handle(
        OKEvent('', false, 'not connect to relay'),
        relay,
        send: (_, __) {
          fail('relay failure should not send data');
        },
        sendAuth: (_) {
          fail('relay failure should not send auth');
        },
        completeRelayRequests: completedRelays.add,
      );

      expect(completedRelays, equals([relay]));
    },
  );
}

ConnectOkHandler _handlerFor({
  ConnectAuthState? authState,
  ConnectSendTracker? sendTracker,
}) {
  return ConnectOkHandler(
    authState: authState ?? ConnectAuthState(),
    sendTracker: sendTracker ?? ConnectSendTracker(),
  );
}
