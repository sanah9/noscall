import 'dart:async';

import 'package:noscall/core/common/utils/log_utils.dart';
import 'connect_dependencies.dart';
import 'connect_socket_registry.dart';
import 'connect_types.dart';
import 'reconnection_scheduler.dart';

typedef ConnectSocketConnectorProvider = RelaySocketConnector Function();
typedef ConnectNetworkStatusProvider = bool Function();
typedef ConnectStatusSetter = void Function(String relay, int status);
typedef ConnectRelayMessageHandler =
    FutureOr<void> Function(String message, String relay);

class ConnectConnectionManager {
  ConnectConnectionManager({
    required ConnectSocketRegistry socketRegistry,
    required ReconnectionScheduler reconnectionScheduler,
    required ConnectSocketConnectorProvider socketConnector,
    required ConnectNetworkStatusProvider hasNetworkConnectivity,
    required ConnectStatusSetter setConnectStatus,
    required ConnectRelayMessageHandler handleMessage,
    required int connectionTimeoutSeconds,
  }) : _socketRegistry = socketRegistry,
       _reconnectionScheduler = reconnectionScheduler,
       _socketConnector = socketConnector,
       _hasNetworkConnectivity = hasNetworkConnectivity,
       _setConnectStatus = setConnectStatus,
       _handleMessage = handleMessage,
       _connectionTimeoutSeconds = connectionTimeoutSeconds;

  final ConnectSocketRegistry _socketRegistry;
  final ReconnectionScheduler _reconnectionScheduler;
  final ConnectSocketConnectorProvider _socketConnector;
  final ConnectNetworkStatusProvider _hasNetworkConnectivity;
  final ConnectStatusSetter _setConnectStatus;
  final ConnectRelayMessageHandler _handleMessage;
  final int _connectionTimeoutSeconds;

  Future<void> connect(
    String relay, {
    required RelayKind relayKind,
    required bool isInitialized,
  }) async {
    LogUtils.v(() => 'connect to $relay, kind: ${relayKind.name}');
    if (relay.isEmpty) return;
    if (!isInitialized) {
      LogUtils.w(
        () =>
            'Connect used before init(); continuing without lifecycle watchers.',
      );
    }

    final relayKinds = _socketRegistry.mergeRelayKind(relay, relayKind);

    if (_socketRegistry.isConnectingOrOpen(relay)) {
      return;
    }

    _reconnectionScheduler.resetRelay(relay);

    LogUtils.v(() => 'connecting... $relay');
    _socketRegistry.markConnecting(relay, relayKinds);
    try {
      final socket = await _connectWs(relay);
      if (socket == null) return;

      socket.done.then((dynamic _) => _onDisconnected(relay, relayKind));
      _listenEvent(socket, relay, relayKind);
      _socketRegistry.markOpen(relay, socket, relayKinds);
      LogUtils.v(() => '$relay connection initialized');
      _setConnectStatus(relay, 1);
      _reconnectionScheduler.recordSuccess(relay);
    } catch (_) {
      _onDisconnected(relay, relayKind);
    }
  }

  Future<void> resetConnection({required bool force}) async {
    for (final relay in List<String>.from(_socketRegistry.relays)) {
      if (_socketRegistry.sockets[relay]?.connectStatus != 3 && force) {
        _socketRegistry.setStatus(relay, 3);
        await _socketRegistry.socketFor(relay)?.close();
      }
      for (final relayKind in _socketRegistry.relayKindsFor(relay)) {
        connect(relay, relayKind: relayKind, isInitialized: true);
      }
    }
  }

  Future<void> closeConnects(List<String> relays, RelayKind relayKind) async {
    await Future.forEach(relays, (String relay) async {
      final relayKinds = _socketRegistry.removeRelayKind(relay, relayKind);
      if (_socketRegistry.contains(relay) && relayKinds.isEmpty) {
        await closeConnect(relay);
      }
    });
  }

  Future<void> closeConnect(String relay) async {
    LogUtils.v(() => 'closeConnect ${_socketRegistry.sockets[relay]?.socket}');
    final socket = _socketRegistry.remove(relay);

    _reconnectionScheduler.cancelRelay(relay);

    await socket?.close();
  }

  Future<void> reconnectToRelay(String relay, RelayKind relayKind) async {
    _setConnectStatus(relay, 3);

    _reconnectionScheduler.schedule(
      relay: relay,
      hasNetworkConnectivity: _hasNetworkConnectivity(),
      isRelayManaged: () => _socketRegistry.contains(relay),
      reconnect: () {
        connect(relay, relayKind: relayKind, isInitialized: true);
      },
    );
  }

  void _listenEvent(RelaySocket socket, String relay, RelayKind relayKind) {
    socket.listen(
      (message) async {
        await _handleMessage(message, relay);
      },
      onDone: () async {
        LogUtils.v(() => 'connect aborted');
        await reconnectToRelay(relay, relayKind);
      },
      onError: (e) async {
        LogUtils.v(() => 'Server error: $e');
        await reconnectToRelay(relay, relayKind);
      },
    );
  }

  Future<RelaySocket?> _connectWs(String relay) async {
    try {
      _setConnectStatus(relay, 0);
      return await _connectWsSetting(relay);
    } catch (e) {
      LogUtils.v(() => 'Error! can not connect WS connectWs $e relay:$relay');
      _setConnectStatus(relay, 3);

      final relayKind = _socketRegistry.firstPersistentKind(relay);
      if (relayKind != null && _socketRegistry.contains(relay)) {
        reconnectToRelay(relay, relayKind);
      }
      return null;
    }
  }

  Future<RelaySocket> _connectWsSetting(String relay) async {
    try {
      return await _socketConnector().connect(
        relay,
        timeout: Duration(seconds: _connectionTimeoutSeconds),
      );
    } on TimeoutException catch (e) {
      LogUtils.v(() => 'WebSocket connection timeout for $relay');
      throw TimeoutException(e.message, e.duration);
    }
  }

  Future<void> _onDisconnected(String relay, RelayKind relayKind) async {
    LogUtils.v(() => '_onDisconnected');
    return await reconnectToRelay(relay, relayKind);
  }
}
