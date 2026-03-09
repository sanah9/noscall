import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Returns state.extra as Map, or null.
Map<String, dynamic>? getRouteParams(GoRouterState state) {
  return state.extra as Map<String, dynamic>?;
}

/// Gets a single param from state.extra map by key. Returns null if missing or wrong type.
T? getRouteParam<T>(GoRouterState state, String key) {
  final params = getRouteParams(state);
  if (params == null) return null;
  final value = params[key];
  return value is T ? value : null;
}

/// If param is null, returns a Scaffold with [notFoundMessage]; otherwise builds with [builder].
Widget buildWithRequiredParam<T>(
  GoRouterState state,
  String key,
  String notFoundMessage,
  Widget Function(T param) builder,
) {
  final param = getRouteParam<T>(state, key);
  if (param == null) {
    return Scaffold(
      body: Center(child: Text(notFoundMessage)),
    );
  }
  return builder(param);
}
