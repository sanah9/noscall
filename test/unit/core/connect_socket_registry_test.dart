import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/core/common/network/connect_socket_registry.dart';
import 'package:noscall/core/common/network/connect_types.dart';

void main() {
  test('mergeRelayKind keeps relay kinds unique and preserves order', () {
    final registry = ConnectSocketRegistry();
    registry.markConnecting('wss://relay.example.com', [RelayKind.general]);

    expect(
      registry.mergeRelayKind('wss://relay.example.com', RelayKind.general),
      equals([RelayKind.general]),
    );
    expect(
      registry.mergeRelayKind('wss://relay.example.com', RelayKind.general),
      equals([RelayKind.general]),
    );
    expect(
      registry.mergeRelayKind('wss://relay.example.com', RelayKind.inbox),
      equals([RelayKind.general, RelayKind.inbox]),
    );
  });

  test('connectedRelays filters by open status and relay kind', () {
    final registry = ConnectSocketRegistry();

    registry.markConnecting('wss://connecting.example.com', [
      RelayKind.general,
    ]);
    registry.markConnecting('wss://open.example.com', [RelayKind.dm]);
    registry.setStatus('wss://open.example.com', 1);

    expect(registry.connectedRelays([RelayKind.general]), isEmpty);
    expect(
      registry.connectedRelays([RelayKind.dm]),
      equals(['wss://open.example.com']),
    );
  });

  test('removeRelayKind removes temp kind with requested kind', () {
    final registry = ConnectSocketRegistry();

    registry.markConnecting('wss://relay.example.com', [
      RelayKind.general,
      RelayKind.temp,
      RelayKind.inbox,
    ]);

    expect(
      registry.removeRelayKind('wss://relay.example.com', RelayKind.inbox),
      equals([RelayKind.general]),
    );
  });

  test('firstPersistentKind skips temp relay kind', () {
    final registry = ConnectSocketRegistry();

    registry.markConnecting('wss://relay.example.com', [
      RelayKind.temp,
      RelayKind.outbox,
      RelayKind.inbox,
    ]);

    expect(
      registry.firstPersistentKind('wss://relay.example.com'),
      RelayKind.outbox,
    );
  });
}
