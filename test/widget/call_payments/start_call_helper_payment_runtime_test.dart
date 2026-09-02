import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/call/start_call_helper.dart';
import 'package:noscall/call_payments/application/call_payment_start_guard.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

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

  testWidgets('shows payment failure when initial payment preparation throws', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var prepareCalls = 0;

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
                  paymentGuard: _paidGuard(),
                  paymentOwner: CashuAccountId.fromNostrPubkey('b' * 64),
                  prepareInitialPayment: (request) async {
                    prepareCalls += 1;
                    throw StateError('duplicate initial payment');
                  },
                  callIdFactory: () => 'call-1',
                  callStartPreflight: (_) async {},
                );
              },
              child: const Text('Call'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Call'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm and call'));
    await tester.pump();

    expect(prepareCalls, 1);
    expect(
      find.text('Paid call payment failed. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Starting voice call...'), findsNothing);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}

CallPaymentStartGuard _paidGuard() {
  final mintUrl = CashuMintUrl.parse('https://mint.example');
  final now = DateTime.utc(2026, 8, 14, 10);
  return CallPaymentStartGuard(
    loadPeerPolicy: (_) async => CallPaymentPolicy(
      owner: CashuAccountId.fromNostrPubkey('a' * 64),
      enabled: true,
      freePolicy: CallPaymentFreePolicy.everyonePays,
      freePubkeys: const [],
      audioPriceSatsPerMinute: 10,
      videoPriceSatsPerMinute: 20,
      billingPeriodSeconds: 60,
      gracePeriodSeconds: 10,
      acceptedMintUrls: [mintUrl],
      createdAt: now,
      updatedAt: now,
    ),
    loadBalancesByMintSats: () async => {mintUrl: 100},
    peerIsContact: (_) => false,
  );
}
