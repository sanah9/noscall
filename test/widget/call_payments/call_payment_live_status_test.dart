import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call_payments/pages/call_payment_live_status.dart';
import '../../helpers/payment_activity_fixtures.dart';

void main() {
  testWidgets('shows prepaid spend, rate and budget warning on small screens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(
            bottomNavigationBar: CallPaymentLiveStatus(
              callId: 'call-1',
              owner: activityOwner,
              loader: (_, _) async => activityCall(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Prepaid 80 / 100 sat'), findsOneWidget);
    expect(find.text('80 sat/min'), findsOneWidget);
    expect(find.text('Approaching spending limit (80%)'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('free calls stay hidden and stale paid status is labelled', (
    tester,
  ) async {
    var reads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CallPaymentLiveStatus(
            callId: 'call-1',
            owner: activityOwner,
            loader: (_, _) async {
              reads++;
              if (reads == 1) return null;
              if (reads == 2) return activityCall();
              throw StateError('database unavailable');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Prepaid'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.textContaining('Prepaid'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('Fee status may be out of date'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
