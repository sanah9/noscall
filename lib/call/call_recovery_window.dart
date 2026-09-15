import 'dart:async';

/// A bounded recovery attempt. Repeated disconnect events cannot extend it.
class CallRecoveryWindow {
  static const gracePeriod = Duration(seconds: 15);
  Timer? _deadline;
  Timer? _retry;
  bool get active => _deadline != null;

  void start({
    required void Function() onTimeout,
    required void Function() onRetry,
  }) {
    if (active) return;
    _deadline = Timer(gracePeriod, () {
      cancel();
      onTimeout();
    });
    _retry = Timer(const Duration(seconds: 2), onRetry);
  }

  void cancel() {
    _deadline?.cancel();
    _retry?.cancel();
    _deadline = null;
    _retry = null;
  }
}
