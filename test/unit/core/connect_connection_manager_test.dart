import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/core/common/network/connect_connection_manager.dart';
import 'package:noscall/core/common/network/connect_dependencies.dart';
import 'package:noscall/core/common/network/connect_socket_registry.dart';
import 'package:noscall/core/common/network/connect_types.dart';
import 'package:noscall/core/common/network/reconnection_scheduler.dart';

void main() {
  test(
    'connect opens relay socket, forwards messages, and closes cleanly',
    () async {
      final registry = ConnectSocketRegistry();
      final scheduler = ReconnectionScheduler();
      final connector = _FakeRelaySocketConnector();
      final statuses = <String>[];
      final messages = <String>[];
      final manager = ConnectConnectionManager(
        socketRegistry: registry,
        reconnectionScheduler: scheduler,
        socketConnector: () => connector,
        hasNetworkConnectivity: () => false,
        setConnectStatus: (relay, status) {
          registry.setStatus(relay, status);
          statuses.add('$relay:$status');
        },
        handleMessage: (message, relay) {
          messages.add('$relay:$message');
        },
        connectionTimeoutSeconds: 10,
      );

      await manager.connect(
        'wss://relay.example.com',
        relayKind: RelayKind.general,
        isInitialized: true,
      );

      expect(connector.connectedRelays, equals(['wss://relay.example.com']));
      expect(registry.sockets['wss://relay.example.com']?.connectStatus, 1);
      expect(statuses, contains('wss://relay.example.com:0'));
      expect(statuses, contains('wss://relay.example.com:1'));

      connector.socketFor('wss://relay.example.com').emit('["NOTICE","hello"]');
      await Future<void>.delayed(Duration.zero);

      expect(messages, equals(['wss://relay.example.com:["NOTICE","hello"]']));

      await manager.closeConnect('wss://relay.example.com');

      expect(registry.contains('wss://relay.example.com'), isFalse);
    },
  );
}

class _FakeRelaySocketConnector implements RelaySocketConnector {
  final Map<String, _FakeRelaySocket> _sockets = {};
  final List<String> connectedRelays = [];

  _FakeRelaySocket socketFor(String relay) => _sockets[relay]!;

  @override
  Future<RelaySocket> connect(
    String relay, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    connectedRelays.add(relay);
    return _sockets.putIfAbsent(relay, _FakeRelaySocket.new);
  }
}

class _FakeRelaySocket implements RelaySocket {
  final StreamController<dynamic> _controller = StreamController<dynamic>();
  final Completer<void> _done = Completer<void>();

  void emit(dynamic event) {
    _controller.add(event);
  }

  @override
  Future<void> get done => _done.future;

  @override
  void add(String data) {}

  @override
  Future<void> close() async {
    if (!_done.isCompleted) {
      _done.complete();
    }
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  @override
  StreamSubscription<dynamic> listen(
    void Function(dynamic event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
