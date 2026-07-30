import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/core/common/network/connect_message_router.dart';

void main() {
  test('routes EVENT messages to event handler', () async {
    final event = Event.partial(id: 'event-1')..subscriptionId = 'sub-1';
    final router = _routerFor('EVENT', event);
    final calls = <String>[];

    await router.route(
      'payload',
      'wss://relay.example.com',
      onEvent: (event, relay) {
        calls.add('$relay:${event.id}:${event.subscriptionId}');
      },
      onEose: (_, __, ___) {},
      onClosed: (_, __) {},
      onNotice: (_, __) {},
      onOk: (_, __) {},
      onAuth: (_, __) {},
    );

    expect(calls, equals(['wss://relay.example.com:event-1:sub-1']));
  });

  test('routes EOSE messages with timeout false', () async {
    final router = _routerFor('EOSE', '["sub-1"]');
    final calls = <String>[];

    await router.route(
      'payload',
      'wss://relay.example.com',
      onEvent: (_, __) {},
      onEose: (eose, relay, timeout) {
        calls.add('$relay:$eose:$timeout');
      },
      onClosed: (_, __) {},
      onNotice: (_, __) {},
      onOk: (_, __) {},
      onAuth: (_, __) {},
    );

    expect(calls, equals(['wss://relay.example.com:["sub-1"]:false']));
  });

  test('routes CLOSED, NOTICE, OK, and AUTH messages', () async {
    final closed = Closed.deserialize(['CLOSED', 'sub-1', 'closed']);
    final ok = OKEvent('event-1', true, '');
    final auth = Auth.deserialize(['AUTH', 'challenge']);
    final calls = <String>[];

    for (final entry in [
      _MessageEntry('CLOSED', closed),
      const _MessageEntry('NOTICE', '["notice"]'),
      _MessageEntry('OK', ok),
      _MessageEntry('AUTH', auth),
    ]) {
      await _routerFor(entry.type, entry.message).route(
        'payload',
        'wss://relay.example.com',
        onEvent: (_, __) {},
        onEose: (_, __, ___) {},
        onClosed: (closed, relay) {
          calls.add('$relay:closed:${closed.subscriptionId}:${closed.message}');
        },
        onNotice: (notice, relay) {
          calls.add('$relay:notice:$notice');
        },
        onOk: (ok, relay) {
          calls.add('$relay:ok:${ok.eventId}:${ok.status}');
        },
        onAuth: (auth, relay) {
          calls.add('$relay:auth:${auth.challenge}');
        },
      );
    }

    expect(
      calls,
      equals([
        'wss://relay.example.com:closed:sub-1:closed',
        'wss://relay.example.com:notice:["notice"]',
        'wss://relay.example.com:ok:event-1:true',
        'wss://relay.example.com:auth:challenge',
      ]),
    );
  });

  test('routes NOTIFY messages through notice handler', () async {
    final router = _routerFor('NOTIFY', '["notice"]');
    final calls = <String>[];

    await router.route(
      'payload',
      'wss://relay.example.com',
      onEvent: (_, __) {},
      onEose: (_, __, ___) {},
      onClosed: (_, __) {},
      onNotice: (notice, relay) {
        calls.add('$relay:$notice');
      },
      onOk: (_, __) {},
      onAuth: (_, __) {},
    );

    expect(calls, equals(['wss://relay.example.com:["notice"]']));
  });

  test('calls unsupported handler for unknown message type', () async {
    final router = _routerFor('REQ', Request('sub-1', []));
    final calls = <String>[];

    await router.route(
      'payload',
      'wss://relay.example.com',
      onEvent: (_, __) {},
      onEose: (_, __, ___) {},
      onClosed: (_, __) {},
      onNotice: (_, __) {},
      onOk: (_, __) {},
      onAuth: (_, __) {},
      onUnsupported: calls.add,
    );

    expect(calls, equals(['payload']));
  });
}

ConnectMessageRouter _routerFor(String type, dynamic message) {
  return ConnectMessageRouter(
    deserializeMessage: (_) async {
      final nostrMessage = Message();
      nostrMessage.type = type;
      nostrMessage.message = message;
      return nostrMessage;
    },
  );
}

class _MessageEntry {
  const _MessageEntry(this.type, this.message);

  final String type;
  final dynamic message;
}
