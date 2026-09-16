import 'call_payment_models.dart';

final class CallPaymentSummary {
  const CallPaymentSummary({
    required this.chargedSats,
    required this.refundedSats,
    required this.reservedSats,
    required this.refundSentSats,
  });

  factory CallPaymentSummary.fromInstallments(
    List<CallPaymentInstallment> installments,
  ) {
    var charged = 0;
    var refunded = 0;
    var reserved = 0;
    var refundSent = 0;
    for (final item in installments) {
      if (item.purpose == CallPaymentPurpose.refund) {
        if (item.status == CallPaymentInstallmentStatus.refunded ||
            item.status == CallPaymentInstallmentStatus.claimed) {
          refunded += item.amountSats;
        } else if (item.direction == CallPaymentTransferDirection.sent &&
            item.status == CallPaymentInstallmentStatus.sent) {
          refunded += item.amountSats;
          refundSent += item.amountSats;
        }
        continue;
      }
      switch (item.status) {
        case CallPaymentInstallmentStatus.sent:
        case CallPaymentInstallmentStatus.received:
        case CallPaymentInstallmentStatus.claimed:
        case CallPaymentInstallmentStatus.reclaimable:
        case CallPaymentInstallmentStatus.reclaimed:
        case CallPaymentInstallmentStatus.unknown:
          charged += item.amountSats;
          if (item.status == CallPaymentInstallmentStatus.reclaimed) {
            refunded += item.amountSats;
          }
        case CallPaymentInstallmentStatus.prepared:
        case CallPaymentInstallmentStatus.failed:
          if (item.walletOperationId != null) reserved += item.amountSats;
        case CallPaymentInstallmentStatus.created:
        case CallPaymentInstallmentStatus.refunded:
          break;
      }
    }
    return CallPaymentSummary(
      chargedSats: charged,
      refundedSats: refunded.clamp(0, charged),
      reservedSats: reserved,
      refundSentSats: refundSent,
    );
  }

  final int chargedSats;
  final int refundedSats;
  final int reservedSats;
  final int refundSentSats;
  int get netSats => chargedSats - refundedSats;
  int get committedSats => chargedSats + reservedSats;

  bool nearBudget(CallPaymentSession session) =>
      session.role == CallPaymentRole.payer &&
      session.maxSpendSats > 0 &&
      committedSats * 100 >= session.maxSpendSats * 80;
}

String callPaymentStatusLabel(CallPaymentSessionStatus status) =>
    switch (status) {
      CallPaymentSessionStatus.reclaimPending => 'Reclaim pending',
      CallPaymentSessionStatus.refundPending => 'Refund pending',
      CallPaymentSessionStatus.completed => 'Completed',
      CallPaymentSessionStatus.paymentFailed => 'Payment failed',
      CallPaymentSessionStatus.insufficientBalance => 'Insufficient balance',
      CallPaymentSessionStatus.noCommonMint => 'No shared Mint',
      CallPaymentSessionStatus.rejected => 'Rejected',
      CallPaymentSessionStatus.timeout => 'Timed out',
      CallPaymentSessionStatus.disputed => 'Disputed',
      CallPaymentSessionStatus.awaitingUserConfirmation =>
        'Awaiting confirmation',
      CallPaymentSessionStatus.preparingInitialPayment => 'Preparing payment',
      CallPaymentSessionStatus.initialPaymentSent => 'Initial payment sent',
      CallPaymentSessionStatus.toppingUp => 'Topping up',
      CallPaymentSessionStatus.connected => 'Connected',
      CallPaymentSessionStatus.ringing => 'Ringing',
      CallPaymentSessionStatus.ending => 'Ending',
      CallPaymentSessionStatus.idle => 'Not started',
    };
