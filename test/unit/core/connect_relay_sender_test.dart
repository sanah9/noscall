import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/core/common/network/connect_relay_sender.dart';
import 'package:noscall/core/common/network/connect_socket_registry.dart';
import 'package:noscall/core/common/network/connect_types.dart';

import '../../helpers/test_setup.dart';

void main() {
  test('sends data to unique open target relays', () {
    final sender = ConnectRelaySender();
    final registry = ConnectSocketRegistry();
    final socket = FakeRelaySocket();

    registry.markOpen('wss://relay.example.com', socket, [RelayKind.general]);

    sender.send(
      'payload',
      socketRegistry: registry,
      onOkFailure: (_, __) {},
      onClosed: (_, __) {},
      toRelays: ['wss://relay.example.com', 'wss://relay.example.com'],
    );

    expect(socket.sentData, equals(['payload']));
  });

  test('reports OK failure for event sent to unavailable target relay', () {
    final sender = ConnectRelaySender();
    final registry = ConnectSocketRegistry();
    final failures = <String>[];

    sender.send(
      'event',
      socketRegistry: registry,
      onOkFailure: (ok, relay) {
        failures.add('$relay:${ok.eventId}:${ok.status}:${ok.message}');
      },
      onClosed: (_, __) {},
      toRelays: ['wss://missing.example.com'],
      eventId: 'event-1',
    );

    expect(
      failures,
      equals(['wss://missing.example.com:event-1:false:not connect to relay']),
    );
  });

  test('reports CLOSED for subscription sent to unavailable target relay', () {
    final sender = ConnectRelaySender();
    final registry = ConnectSocketRegistry();
    final closed = <String>[];

    sender.send(
      'subscription',
      socketRegistry: registry,
      onOkFailure: (_, __) {},
      onClosed: (event, relay) {
        closed.add('$relay:${event.subscriptionId}');
      },
      toRelays: ['wss://missing.example.com'],
      subscriptionId: 'sub-1',
    );

    expect(closed, equals(['wss://missing.example.com:sub-1']));
  });

  test(
    'broadcast sends to open relays and reports failures for closed relays',
    () {
      final sender = ConnectRelaySender();
      final registry = ConnectSocketRegistry();
      final openSocket = FakeRelaySocket();
      final failures = <String>[];

      registry.markOpen('wss://open.example.com', openSocket, [
        RelayKind.general,
      ]);
      registry.markConnecting('wss://connecting.example.com', [
        RelayKind.general,
      ]);

      sender.send(
        'event',
        socketRegistry: registry,
        onOkFailure: (ok, relay) {
          failures.add('$relay:${ok.eventId}:${ok.status}:${ok.message}');
        },
        onClosed: (_, __) {},
        eventId: 'event-1',
      );

      expect(openSocket.sentData, equals(['event']));
      expect(
        failures,
        equals([
          'wss://connecting.example.com:event-1:false:not connect to relay',
        ]),
      );
    },
  );
}
