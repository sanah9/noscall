import 'dart:async';

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class FakeConnectivityPlatform extends ConnectivityPlatform {
  FakeConnectivityPlatform({
    List<ConnectivityResult> initialResults = const [ConnectivityResult.none],
    Stream<List<ConnectivityResult>>? changes,
  })  : _initialResults = initialResults,
        _changes = changes ?? const Stream<List<ConnectivityResult>>.empty();

  final List<ConnectivityResult> _initialResults;
  final Stream<List<ConnectivityResult>> _changes;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _initialResults;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _changes;
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(label)),
    );
  }
}

Future<GoRouter> pumpRouterApp(
  WidgetTester tester, {
  required String initialLocation,
  required List<RouteBase> routes,
}) async {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: routes,
  );

  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
