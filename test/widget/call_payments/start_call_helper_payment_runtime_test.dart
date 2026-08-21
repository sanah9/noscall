import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/call/start_call_helper.dart';

void main() {
  testWidgets('cancels call start when payment precheck is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () {
                StartCallHelper.startCall(
                  context,
                  peerId: 'a' * 64,
                  callType: CallType.audio,
                  paymentRuntimeFactory: () async => null,
                );
              },
              child: const Text('Call'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Call'));
    await tester.pump();

    expect(
      find.text(
        'Paid call payment check is unavailable. Please try again later.',
      ),
      findsOneWidget,
    );
    expect(find.text('Starting voice call...'), findsNothing);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
