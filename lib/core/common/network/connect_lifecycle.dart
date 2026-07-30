import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'connect_dependencies.dart';

class ConnectLifecycle {
  Timer? timer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  ConnectivityResult? _currentConnectivity;

  bool get hasNetworkConnectivity {
    return _currentConnectivity != null &&
        _currentConnectivity != ConnectivityResult.none;
  }

  void startHeartbeat({
    required void Function() onTimeoutCheck,
    required FutureOr<void> Function() onResetConnection,
  }) {
    if (timer == null || timer!.isActive == false) {
      timer = Timer.periodic(const Duration(seconds: 5), (_) {
        onTimeoutCheck();
      });
    }
    onResetConnection();
  }

  Future<void> listenConnectivity(
    ConnectConnectivity connectivity, {
    required FutureOr<void> Function() onNetworkAvailable,
  }) async {
    final results = await connectivity.checkConnectivity();
    _currentConnectivity = results.isNotEmpty ? results.first : null;

    _connectivitySubscription ??= connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _currentConnectivity = results.isNotEmpty ? results.first : null;
      if (results.any((result) => result != ConnectivityResult.none)) {
        onNetworkAvailable();
      }
    });
  }

  Future<void> stop() async {
    timer?.cancel();
    timer = null;

    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;

    _currentConnectivity = null;
  }
}
