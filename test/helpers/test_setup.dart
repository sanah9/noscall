import 'dart:async';

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';

class TestSetup {
  static ConnectivityPlatform? _previousConnectivityPlatform;

  /// Installs a deterministic connectivity fallback for tests that touch
  /// singleton startup paths before a real platform implementation exists.
  static void installConnectivityFallback({
    List<ConnectivityResult> initialResults = const [ConnectivityResult.none],
  }) {
    _previousConnectivityPlatform ??= ConnectivityPlatform.instance;
    ConnectivityPlatform.instance = _FakeConnectivityPlatform(initialResults);
  }

  /// Restores the connectivity platform implementation after tests complete.
  static void restoreConnectivityPlatform() {
    final previous = _previousConnectivityPlatform;
    if (previous == null) return;
    ConnectivityPlatform.instance = previous;
    _previousConnectivityPlatform = null;
  }
}

class _FakeConnectivityPlatform extends ConnectivityPlatform {
  _FakeConnectivityPlatform(this._results);

  final List<ConnectivityResult> _results;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _results;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream<List<ConnectivityResult>>.empty();
}
