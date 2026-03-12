import 'dart:async';

/// Encapsulates invite timeout: single timer that fires once after [duration].
/// Cancel or dispose when invite is accepted, call ends, or controller disposes.
class CallInviteTimeout {
  Timer? _timer;

  /// Starts the timeout; cancels any existing one. [onTimeout] is called once after [duration].
  void start(Duration duration, void Function() onTimeout) {
    _timer?.cancel();
    _timer = Timer(duration, onTimeout);
  }

  /// Cancels the current timeout without disposing.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Releases resources. Call when the owner is disposed.
  void dispose() {
    cancel();
  }
}
