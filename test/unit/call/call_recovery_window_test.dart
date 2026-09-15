import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call/call_recovery_window.dart';

void main() {
  test('retries once and repeated interruptions cannot extend deadline', () {
    fakeAsync((time) {
      final recovery = CallRecoveryWindow();
      var retries = 0;
      var timeouts = 0;
      void start() =>
          recovery.start(onTimeout: () => timeouts++, onRetry: () => retries++);
      start();
      time.elapse(const Duration(seconds: 2));
      expect(retries, 1);
      start();
      time.elapse(const Duration(seconds: 13));
      expect(timeouts, 1);
      expect(recovery.active, isFalse);
    });
  });

  test('successful recovery or hangup cancels pending actions', () {
    fakeAsync((time) {
      final recovery = CallRecoveryWindow();
      recovery.start(
        onTimeout: () => fail('timeout after cancellation'),
        onRetry: () => fail('retry after cancellation'),
      );
      time.elapse(const Duration(seconds: 1));
      recovery.cancel();
      time.elapse(const Duration(minutes: 1));
      expect(recovery.active, isFalse);
    });
  });
}
