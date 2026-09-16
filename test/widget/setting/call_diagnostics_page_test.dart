import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call/call_diagnostics_service.dart';
import 'package:noscall/setting/pages/call_diagnostics_page.dart';

class FakeDiagnostics extends CallDiagnosticsBackend {
  bool mobile = true;
  bool failRead = false;
  bool failTest = false;
  int tests = 0;
  int repairs = 0;
  @override
  Future<CallDiagnosticsSnapshot> read() async {
    if (failRead) throw StateError('offline');
    return CallDiagnosticsSnapshot(
      mobile: mobile,
      checks: const [
        CallDiagnostic(
          'microphone',
          'Microphone',
          'Allowed',
          CallDiagnosticStatus.ready,
        ),
        CallDiagnostic(
          'remote',
          'Remote delivery',
          'Not verified',
          CallDiagnosticStatus.unknown,
        ),
      ],
    );
  }

  @override
  Future<void> repair() async {
    repairs++;
  }

  @override
  Future<void> testLocalNotification() async {
    tests++;
    if (failTest) throw StateError('denied');
  }
}

void main() {
  testWidgets('local test never claims remote delivery succeeded', (
    tester,
  ) async {
    final backend = FakeDiagnostics();
    await tester.pumpWidget(
      MaterialApp(home: CallDiagnosticsPage(backend: backend)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test local notification'));
    await tester.pumpAndSettle();
    expect(backend.tests, 1);
    expect(
      find.textContaining('Remote delivery has not been tested.'),
      findsOneWidget,
    );
    expect(find.text('Not verified'), findsOneWidget);
  });

  testWidgets('reports failure and permits refresh recovery', (tester) async {
    final backend = FakeDiagnostics()..failRead = true;
    await tester.pumpWidget(
      MaterialApp(home: CallDiagnosticsPage(backend: backend)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Check could not complete'), findsOneWidget);
    backend.failRead = false;
    await tester.tap(find.byTooltip('Refresh diagnostics'));
    await tester.pumpAndSettle();
    expect(find.text('Microphone'), findsOneWidget);
    backend.failTest = true;
    await tester.tap(find.text('Test local notification'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Check could not complete'), findsOneWidget);
    expect(find.textContaining('Local notification requested'), findsNothing);
  });

  testWidgets('desktop does not offer unavailable push tests or repair', (
    tester,
  ) async {
    final backend = FakeDiagnostics()..mobile = false;
    await tester.pumpWidget(
      MaterialApp(home: CallDiagnosticsPage(backend: backend)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Test local notification'), findsNothing);
    expect(find.text('Refresh registration'), findsNothing);
  });

  testWidgets('narrow layouts fit and repair refreshes evidence', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final backend = FakeDiagnostics();
    await tester.pumpWidget(
      MaterialApp(home: CallDiagnosticsPage(backend: backend)),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Refresh registration'), 100);
    await tester.tap(find.text('Refresh registration'));
    await tester.pumpAndSettle();
    expect(backend.repairs, 1);
    expect(
      find.textContaining('remote delivery is still unverified'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
