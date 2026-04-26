import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:noscall/core/common/network/connect_dependencies.dart';

class TestSetup {
  static ConnectConnectivity connectivity({
    List<ConnectivityResult> initialResults = const [ConnectivityResult.none],
    Stream<List<ConnectivityResult>>? changes,
  }) {
    return FakeConnectConnectivity(
      initialResults: initialResults,
      changes: changes,
    );
  }

  static RelaySocketConnector socketConnector({
    Map<String, FakeRelaySocket>? socketsByRelay,
  }) {
    return FakeRelaySocketConnector(socketsByRelay: socketsByRelay);
  }
}

class FakeConnectConnectivity implements ConnectConnectivity {
  FakeConnectConnectivity({
    this.initialResults = const [ConnectivityResult.none],
    Stream<List<ConnectivityResult>>? changes,
  }) : _changes = changes ?? const Stream<List<ConnectivityResult>>.empty();

  final List<ConnectivityResult> initialResults;
  final Stream<List<ConnectivityResult>> _changes;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => initialResults;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _changes;
}

class FakeRelaySocketConnector implements RelaySocketConnector {
  FakeRelaySocketConnector({Map<String, FakeRelaySocket>? socketsByRelay})
      : socketsByRelay = socketsByRelay ?? {};

  final Map<String, FakeRelaySocket> socketsByRelay;
  final List<String> connectedRelays = [];

  @override
  Future<RelaySocket> connect(
    String relay, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    connectedRelays.add(relay);
    return socketsByRelay.putIfAbsent(relay, () => FakeRelaySocket());
  }
}

class FakeRelaySocket implements RelaySocket {
  final StreamController<dynamic> _controller = StreamController<dynamic>();
  final Completer<void> _done = Completer<void>();
  final List<String> sentData = [];

  @override
  Future<void> get done => _done.future;

  @override
  void add(String data) {
    sentData.add(data);
  }

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
