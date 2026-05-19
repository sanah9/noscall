import 'dart:async';

import 'package:noscall/core/common/utils/log_utils.dart';

import 'reconnection_state.dart';

class ReconnectionScheduler {
  final Map<String, Timer> _timers = {};
  final Map<String, ReconnectionState> _states = {};

  Iterable<ReconnectionState> get states => _states.values;

  void resetAll() {
    for (final state in _states.values) {
      state.reset();
    }
  }

  void resetRelay(String relay) {
    _states[relay]?.reset();
  }

  void recordSuccess(String relay) {
    _states[relay]?.recordSuccess();
  }

  void cancelRelay(String relay) {
    _timers[relay]?.cancel();
    _timers.remove(relay);
    _states.remove(relay);
  }

  void cancelAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _states.clear();
  }

  bool schedule({
    required String relay,
    required bool hasNetworkConnectivity,
    required bool Function() isRelayManaged,
    required void Function() reconnect,
  }) {
    if (!isRelayManaged()) {
      LogUtils.v(
          () => 'Skipping reconnection for relay no longer managed: $relay');
      return false;
    }

    final state = _states[relay] ??= ReconnectionState();

    if (state.isReconnecting) {
      LogUtils.v(() => 'Reconnection already in progress for $relay');
      return false;
    }

    if (!hasNetworkConnectivity) {
      LogUtils.v(
          () => 'No network connectivity, skipping reconnection for $relay');
      return false;
    }

    if (!state.shouldReconnect()) {
      LogUtils.v(() =>
          'Reconnection limit reached or in cooldown for $relay (attempts: ${state.attemptCount})');
      return false;
    }

    state.recordAttempt();
    final backoffDelay = state.getBackoffDelay();

    LogUtils.v(() =>
        'Scheduling reconnection for $relay in ${backoffDelay.inSeconds}s (attempt ${state.attemptCount})');

    _timers[relay]?.cancel();
    _timers[relay] = Timer(backoffDelay, () {
      _timers.remove(relay);
      state.isReconnecting = false;

      if (isRelayManaged()) {
        reconnect();
      }
    });
    return true;
  }
}
