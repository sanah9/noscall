import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Listens to connectivity changes and invokes [onNetworkDisconnected] when
/// all results are [ConnectivityResult.none]. Cancel via [dispose].
class CallConnectivityListener {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Starts listening. [onNetworkDisconnected] is called when network goes offline.
  void start(void Function() onNetworkDisconnected, {void Function(dynamic)? onError}) {
    _subscription?.cancel();
    _subscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        if (results.every((r) => r == ConnectivityResult.none)) {
          onNetworkDisconnected();
        }
      },
      onError: onError,
    );
  }

  /// Stops listening. Call when the call ends or controller is disposed.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
