import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/domain/call_payment_summary.dart';
import '../../helpers/payment_activity_fixtures.dart';

void main() {
  test(
    'uses installments, warns at 80 percent and includes reserved funds',
    () {
      final data = activityCall(
        installments: [
          activityInstallment(amount: 60),
          activityInstallment(
            amount: 20,
            sequence: 2,
            status: CallPaymentInstallmentStatus.prepared,
          ),
        ],
      );
      expect(data.summary.chargedSats, 60);
      expect(data.summary.reservedSats, 20);
      expect(data.summary.nearBudget(data.session), isTrue);
      expect(
        activityCall(
          installments: [activityInstallment(amount: 79)],
        ).summary.nearBudget(data.session),
        isFalse,
      );
      expect(
        data.summary.nearBudget(
          activityCall(role: CallPaymentRole.payee).session,
        ),
        isFalse,
      );
    },
  );
  test(
    'pending incoming refunds do not reduce net spend, received refunds do',
    () {
      final original = activityInstallment();
      final pending = activityInstallment(
        amount: 20,
        purpose: CallPaymentPurpose.refund,
        direction: CallPaymentTransferDirection.received,
        status: CallPaymentInstallmentStatus.received,
      );
      expect(
        CallPaymentSummary.fromInstallments([original, pending]).netSats,
        80,
      );
      final complete = pending.copyWith(
        status: CallPaymentInstallmentStatus.refunded,
      );
      expect(
        CallPaymentSummary.fromInstallments([original, complete]).netSats,
        60,
      );
    },
  );
  test('outgoing refund sent is distinguished from confirmed receipt', () {
    final summary = CallPaymentSummary.fromInstallments([
      activityInstallment(),
      activityInstallment(amount: 20, purpose: CallPaymentPurpose.refund),
    ]);
    expect(summary.refundedSats, 20);
    expect(summary.refundSentSats, 20);
  });
  test(
    'reclaims offset original payments once and never produce negative net',
    () {
      final summary = CallPaymentSummary.fromInstallments([
        activityInstallment(status: CallPaymentInstallmentStatus.reclaimed),
        activityInstallment(
          amount: 100,
          purpose: CallPaymentPurpose.refund,
          status: CallPaymentInstallmentStatus.refunded,
        ),
      ]);
      expect(summary.netSats, 0);
      expect(summary.refundedSats, 80);
    },
  );
}
