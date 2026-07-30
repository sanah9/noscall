import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/core/common/network/connect_lifecycle.dart';

import '../../helpers/test_setup.dart';

void main() {
  test('startHeartbeat creates timer and invokes reset callback', () async {
    final lifecycle = ConnectLifecycle();
    var timeoutChecks = 0;
    var resets = 0;

    lifecycle.startHeartbeat(
      onTimeoutCheck: () {
        timeoutChecks++;
      },
      onResetConnection: () {
        resets++;
      },
    );

    expect(lifecycle.timer, isNotNull);
    expect(timeoutChecks, 0);
    expect(resets, 1);

    await lifecycle.stop();

    expect(lifecycle.timer, isNull);
  });

  test('listenConnectivity records initial network state', () async {
    final lifecycle = ConnectLifecycle();

    await lifecycle.listenConnectivity(
      TestSetup.connectivity(initialResults: const [ConnectivityResult.wifi]),
      onNetworkAvailable: () {},
    );

    expect(lifecycle.hasNetworkConnectivity, isTrue);

    await lifecycle.stop();

    expect(lifecycle.hasNetworkConnectivity, isFalse);
  });

  test(
    'listenConnectivity invokes callback when network becomes available',
    () async {
      final lifecycle = ConnectLifecycle();
      final changes = StreamController<List<ConnectivityResult>>();
      var networkAvailableCalls = 0;

      await lifecycle.listenConnectivity(
        TestSetup.connectivity(
          initialResults: const [ConnectivityResult.none],
          changes: changes.stream,
        ),
        onNetworkAvailable: () {
          networkAvailableCalls++;
        },
      );

      expect(lifecycle.hasNetworkConnectivity, isFalse);

      changes.add(const [ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);
      expect(networkAvailableCalls, 0);

      changes.add(const [ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);

      expect(lifecycle.hasNetworkConnectivity, isTrue);
      expect(networkAvailableCalls, 1);

      await lifecycle.stop();
      await changes.close();
    },
  );
}
