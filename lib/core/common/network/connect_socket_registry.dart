import 'connect_dependencies.dart';
import 'connect_types.dart';

class ConnectSocketRegistry {
  final Map<String, ISocket> sockets = {};

  Iterable<String> get relays => sockets.keys;

  bool contains(String relay) => sockets.containsKey(relay);

  bool isConnectingOrOpen(String relay) {
    final status = sockets[relay]?.connectStatus;
    return status == 0 || status == 1;
  }

  List<RelayKind> relayKindsFor(String relay) {
    return sockets[relay]?.relayKinds ?? const [];
  }

  List<RelayKind> mergeRelayKind(String relay, RelayKind relayKind) {
    final relayKinds = List<RelayKind>.from(
      sockets[relay]?.relayKinds ?? [relayKind],
    );
    if (!relayKinds.contains(relayKind)) {
      relayKinds.add(relayKind);
    }
    sockets[relay]?.relayKinds = relayKinds;
    return relayKinds;
  }

  void markConnecting(String relay, List<RelayKind> relayKinds) {
    sockets[relay] = ISocket(null, 0, relayKinds);
  }

  void markOpen(String relay, RelaySocket socket, List<RelayKind> relayKinds) {
    sockets[relay] = ISocket(socket, 1, relayKinds);
  }

  void setStatus(String relay, int status) {
    sockets[relay]?.connectStatus = status;
  }

  RelaySocket? remove(String relay) {
    return sockets.remove(relay)?.socket;
  }

  void clear() {
    sockets.clear();
  }

  List<String> connectedRelays(List<RelayKind> relayKinds) {
    final result = <String>[];
    for (final relay in sockets.keys) {
      final socket = sockets[relay];
      if (socket?.connectStatus == 1 &&
          socket!.relayKinds.any((kind) => relayKinds.contains(kind))) {
        result.add(relay);
      }
    }
    return result;
  }

  List<RelayKind> removeRelayKind(String relay, RelayKind relayKind) {
    final relayKinds = sockets[relay]?.relayKinds;
    if (relayKinds == null) return const [];
    relayKinds.removeWhere(
      (kind) => kind == RelayKind.temp || kind == relayKind,
    );
    return relayKinds;
  }

  RelaySocket? socketFor(String relay) {
    return sockets[relay]?.socket;
  }

  bool isOpen(String relay) {
    return sockets[relay]?.connectStatus == 1 && sockets[relay]?.socket != null;
  }

  RelayKind? firstPersistentKind(String relay) {
    final relayKinds = sockets[relay]?.relayKinds;
    if (relayKinds == null) return null;
    for (final relayKind in relayKinds) {
      if (relayKind != RelayKind.temp) return relayKind;
    }
    return null;
  }
}
