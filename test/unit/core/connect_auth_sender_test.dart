import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/core/common/network/connect_auth_sender.dart';
import 'package:noscall/core/common/network/connect_auth_state.dart';

Auth authChallenge(String challenge) {
  return Auth.deserialize(['AUTH', challenge]);
}

void main() {
  test('does nothing when relay has no challenge', () async {
    final state = ConnectAuthState();
    final sender = _senderFor(state);
    final sent = <String>[];

    await sender.sendAuth(
      'wss://relay.example.com',
      send: (data, relays) {
        sent.add('${relays.single}:$data');
      },
    );

    expect(sent, isEmpty);
  });

  test('encodes auth event, marks it sent, and sends auth payload', () async {
    final state = ConnectAuthState();
    const relay = 'wss://relay.example.com';
    state.registerChallenge(authChallenge('challenge-1'), relay);
    final sender = _senderFor(state);
    final sent = <String>[];

    await sender.sendAuth(
      relay,
      send: (data, relays) {
        sent.add('${relays.single}:$data');
      },
    );

    expect(sent, equals(['$relay:auth:event-challenge-1']));
    expect(state.auths[relay]?.eventId, 'event-challenge-1');
  });

  test(
    'does not send duplicate auth while an auth event is in flight',
    () async {
      final state = ConnectAuthState();
      const relay = 'wss://relay.example.com';
      state.registerChallenge(authChallenge('challenge-1'), relay);
      final sender = _senderFor(state);
      final sent = <String>[];

      await sender.sendAuth(
        relay,
        send: (data, _) {
          sent.add(data);
        },
      );
      await sender.sendAuth(
        relay,
        send: (data, _) {
          sent.add(data);
        },
      );

      expect(sent, equals(['auth:event-challenge-1']));
    },
  );
}

ConnectAuthSender _senderFor(ConnectAuthState state) {
  return ConnectAuthSender(
    authState: state,
    pubkey: () => 'pubkey',
    privkey: () => 'privkey',
    encodeAuthEvent: (challenge, relay, pubkey, privkey) async {
      expect(relay, 'wss://relay.example.com');
      expect(pubkey, 'pubkey');
      expect(privkey, 'privkey');
      return Event.partial(id: 'event-$challenge');
    },
    authString: (event) => 'auth:${event.id}',
  );
}
