import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/core/common/network/connect_auth_state.dart';

Auth authChallenge(String challenge) {
  return Auth.deserialize(['AUTH', challenge]);
}

void main() {
  group('ConnectAuthState', () {
    test('registerChallenge creates and updates relay auth state', () {
      final state = ConnectAuthState();
      const relay = 'wss://relay.example.com';

      state.registerChallenge(authChallenge('challenge-1'), relay);

      expect(state.challengeFor(relay), 'challenge-1');
      expect(state.auths[relay]?.eventId, isEmpty);

      state.markSending(relay);
      state.markSent(relay, 'event-id');
      state.registerChallenge(authChallenge('challenge-2'), relay);

      expect(state.challengeFor(relay), 'challenge-2');
      expect(state.auths[relay]?.eventId, isEmpty);
    });

    test('queueResend deduplicates data and requires auth state', () {
      final state = ConnectAuthState();
      const relay = 'wss://relay.example.com';

      expect(state.queueResend(relay, 'data-1'), isFalse);

      state.registerChallenge(authChallenge('challenge-1'), relay);

      expect(state.queueResend(relay, 'data-1'), isTrue);
      expect(state.queueResend(relay, 'data-1'), isFalse);
      expect(state.auths[relay]?.resendDatas, ['data-1']);
    });

    test('completeAuthResponse returns queued data only for successful auth',
        () {
      final state = ConnectAuthState();
      const relay = 'wss://relay.example.com';

      state.registerChallenge(authChallenge('challenge-1'), relay);
      state.queueResend(relay, 'data-1');
      state.markSending(relay);
      state.markSent(relay, 'auth-event-id');

      final queued = state.completeAuthResponse(
        OKEvent('auth-event-id', true, ''),
        relay,
      );

      expect(queued, ['data-1']);
      expect(state.auths.containsKey(relay), isFalse);

      state.registerChallenge(authChallenge('challenge-2'), relay);
      state.queueResend(relay, 'data-2');
      state.markSending(relay);
      state.markSent(relay, 'auth-event-id-2');

      final failedQueued = state.completeAuthResponse(
        OKEvent('auth-event-id-2', false, 'blocked'),
        relay,
      );

      expect(failedQueued, isEmpty);
      expect(state.auths.containsKey(relay), isFalse);
    });

    test('markSending prevents duplicate in-flight auth sends', () {
      final state = ConnectAuthState();
      const relay = 'wss://relay.example.com';

      expect(state.markSending(relay), isFalse);

      state.registerChallenge(authChallenge('challenge-1'), relay);

      expect(state.markSending(relay), isTrue);
      expect(state.markSending(relay), isFalse);
    });
  });
}
