import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call/call_diagnostics_service.dart';

void main() {
  test('only recent accepted subscriptions count as locally ready', () {
    final now = DateTime.utc(2026, 9, 16);
    expect(
      CallDiagnosticsSnapshot.subscription('wss://relay', now, now).status,
      CallDiagnosticStatus.ready,
    );
    for (final accepted in [
      null,
      now.subtract(const Duration(days: 2)),
      now.add(const Duration(minutes: 1)),
    ]) {
      expect(
        CallDiagnosticsSnapshot.subscription(
          'wss://relay',
          accepted,
          now,
        ).status,
        CallDiagnosticStatus.attention,
      );
    }
  });
}
