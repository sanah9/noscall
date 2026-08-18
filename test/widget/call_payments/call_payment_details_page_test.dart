import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/pages/call_payment_details_page.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  testWidgets('shows session totals and installments', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: CallPaymentDetailsPage(
          arguments: CallPaymentDetailsArguments(
            callId: 'call-1',
            accountId: _owner,
          ),
          loader: (_, _) async => _details(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('12 sat net'), findsOneWidget);
    expect(find.text('Refund pending'), findsOneWidget);
    expect(find.text('20 sat'), findsOneWidget);
    expect(find.text('8 sat'), findsNWidgets(2));
    expect(find.text('Initial #1'), findsOneWidget);
    expect(find.text('Top up #2'), findsOneWidget);
    expect(find.text('Refund #1'), findsOneWidget);
    expect(find.text('Ordinary token payment'), findsOneWidget);
  });

  testWidgets('shows empty state for free calls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CallPaymentDetailsPage(
          arguments: CallPaymentDetailsArguments(
            callId: 'free-call',
            accountId: _owner,
          ),
          loader: (_, _) async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No paid call payment found'), findsOneWidget);
  });
}

CallPaymentDetailsData _details() {
  final now = DateTime.utc(2026, 8, 18, 12);
  return CallPaymentDetailsData(
    session: CallPaymentSession(
      owner: _owner,
      callId: 'call-1',
      peerPubkey: 'b' * 64,
      direction: CallPaymentCallDirection.outgoing,
      role: CallPaymentRole.payer,
      callType: CallPaymentCallType.audio,
      status: CallPaymentSessionStatus.refundPending,
      mintUrl: _mint,
      priceSatsPerMinute: 10,
      billingPeriodSeconds: 60,
      maxSpendSats: 100,
      connectedAt: now,
      endedAt: now.add(const Duration(seconds: 70)),
      connectedDurationSeconds: 70,
      chargedSats: 20,
      refundedSats: 8,
      createdAt: now,
      updatedAt: now,
    ),
    installments: [
      _installment(
        sequence: 1,
        purpose: CallPaymentPurpose.initial,
        direction: CallPaymentTransferDirection.sent,
        amountSats: 10,
        status: CallPaymentInstallmentStatus.claimed,
      ),
      _installment(
        sequence: 2,
        purpose: CallPaymentPurpose.topUp,
        direction: CallPaymentTransferDirection.sent,
        amountSats: 10,
        status: CallPaymentInstallmentStatus.sent,
      ),
      _installment(
        sequence: 1,
        purpose: CallPaymentPurpose.refund,
        direction: CallPaymentTransferDirection.received,
        amountSats: 8,
        status: CallPaymentInstallmentStatus.refunded,
      ),
    ],
  );
}

CallPaymentInstallment _installment({
  required int sequence,
  required CallPaymentPurpose purpose,
  required CallPaymentTransferDirection direction,
  required int amountSats,
  required CallPaymentInstallmentStatus status,
}) {
  final now = DateTime.utc(2026, 8, 18, 12);
  return CallPaymentInstallment(
    owner: _owner,
    callId: 'call-1',
    paymentSessionId: 'call-1:payer',
    sequence: sequence,
    purpose: purpose,
    direction: direction,
    amountSats: amountSats,
    mintUrl: _mint,
    status: status,
    coversFromSecond: (sequence - 1) * 60,
    coversToSecond: sequence * 60,
    createdAt: now,
    updatedAt: now,
  );
}

final _owner = CashuAccountId.fromNostrPubkey('a' * 64);
final _mint = CashuMintUrl.parse('https://mint.example');
