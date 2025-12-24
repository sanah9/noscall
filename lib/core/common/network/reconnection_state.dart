class ReconnectionState {
  int attemptCount;
  DateTime lastAttemptTime;
  DateTime? lastSuccessTime;
  bool isReconnecting;

  ReconnectionState({
    this.attemptCount = 0,
    DateTime? lastAttemptTime,
    this.lastSuccessTime,
    this.isReconnecting = false,
  }) : lastAttemptTime = lastAttemptTime ?? DateTime.now();

  void reset() {
    attemptCount = 0;
    lastAttemptTime = DateTime.now();
    isReconnecting = false;
  }

  void recordAttempt() {
    attemptCount++;
    lastAttemptTime = DateTime.now();
    isReconnecting = true;
  }

  void recordSuccess() {
    lastSuccessTime = DateTime.now();
    isReconnecting = false;
    attemptCount = 0;
  }

  Duration getBackoffDelay() {
    if (attemptCount == 0) return const Duration(seconds: 3);

    const baseDelay = 3;
    const maxDelay = 60;
    final delay = (baseDelay * (1 << (attemptCount - 1))).clamp(baseDelay, maxDelay);
    return Duration(seconds: delay);
  }

  bool shouldReconnect({int maxAttempts = 10, Duration cooldownPeriod = const Duration(seconds: 5)}) {
    if (attemptCount >= maxAttempts) {
      return false;
    }

    if (lastSuccessTime != null) {
      final timeSinceSuccess = DateTime.now().difference(lastSuccessTime!);
      if (timeSinceSuccess < cooldownPeriod) {
        return false;
      }
    }

    final timeSinceLastAttempt = DateTime.now().difference(lastAttemptTime);
    final backoffDelay = getBackoffDelay();
    if (timeSinceLastAttempt < backoffDelay) {
      return false;
    }

    return true;
  }
}