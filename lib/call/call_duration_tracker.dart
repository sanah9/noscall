import 'dart:async';
import 'package:flutter/foundation.dart';

/// Tracks call connection duration using Stopwatch + periodic Timer + ValueNotifier.
/// Start when WebRTC connects; stop on hangup. Reusable and testable.
class CallDurationTracker {
  final ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  /// Starts the stopwatch and a periodic timer that updates [duration] every second.
  void start() {
    if (_timer != null && _timer!.isActive) return;
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      duration.value = _stopwatch.elapsed;
    });
  }

  /// Stops the stopwatch and cancels the timer. [elapsed] remains valid afterward.
  void stop() {
    _stopwatch.stop();
    _timer?.cancel();
    _timer = null;
    duration.value = _stopwatch.elapsed;
  }

  /// Current elapsed duration (from running stopwatch or last value after stop).
  Duration get elapsed =>
      _stopwatch.isRunning ? _stopwatch.elapsed : duration.value;

  /// Releases resources. Call when the owner is disposed.
  void dispose() {
    stop();
  }
}
