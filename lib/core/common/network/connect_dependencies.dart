import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

abstract interface class ConnectConnectivity {
  Future<List<ConnectivityResult>> checkConnectivity();

  Stream<List<ConnectivityResult>> get onConnectivityChanged;
}

class DefaultConnectConnectivity implements ConnectConnectivity {
  DefaultConnectConnectivity({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() {
    return _connectivity.checkConnectivity();
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }
}

abstract interface class RelaySocket {
  Future<dynamic> get done;

  void add(String data);

  Future<void> close();

  StreamSubscription<dynamic> listen(
    void Function(dynamic event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  });
}

class WebSocketRelaySocket implements RelaySocket {
  WebSocketRelaySocket(this._socket);

  final WebSocket _socket;

  @override
  Future<dynamic> get done => _socket.done;

  @override
  void add(String data) {
    _socket.add(data);
  }

  @override
  Future<void> close() async {
    await _socket.close();
  }

  @override
  StreamSubscription<dynamic> listen(
    void Function(dynamic event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _socket.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

abstract interface class RelaySocketConnector {
  Future<RelaySocket> connect(
    String relay, {
    Duration timeout = const Duration(seconds: 10),
  });
}

class DefaultRelaySocketConnector implements RelaySocketConnector {
  const DefaultRelaySocketConnector();

  @override
  Future<RelaySocket> connect(
    String relay, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final socket = await WebSocket.connect(relay).timeout(
      timeout,
      onTimeout: () {
        throw TimeoutException(
          'Connection timeout after ${timeout.inSeconds}s',
          timeout,
        );
      },
    );
    return WebSocketRelaySocket(socket);
  }
}
