import 'package:noscall/call_payments/application/call_payment_details.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

final activityOwner = CashuAccountId.fromNostrPubkey('a' * 64);
final activityMint = CashuMintUrl.parse('https://mint.example');
final activityTime = DateTime.utc(2026, 9, 16, 12);

CallPaymentInstallment activityInstallment({
  int amount = 80,
  int sequence = 1,
  CallPaymentPurpose purpose = CallPaymentPurpose.initial,
  CallPaymentTransferDirection direction = CallPaymentTransferDirection.sent,
  CallPaymentInstallmentStatus status = CallPaymentInstallmentStatus.sent,
  String? operationId = 'call-operation',
}) => CallPaymentInstallment(
  owner: activityOwner,
  callId: 'call-1',
  paymentSessionId: 'call-1:payer',
  sequence: sequence,
  purpose: purpose,
  direction: direction,
  amountSats: amount,
  mintUrl: activityMint,
  status: status,
  coversFromSecond: 0,
  coversToSecond: 60,
  createdAt: activityTime,
  updatedAt: activityTime,
  walletOperationId: operationId,
);

CallPaymentDetailsData activityCall({
  List<CallPaymentInstallment>? installments,
  CallPaymentRole role = CallPaymentRole.payer,
  CallPaymentSessionStatus status = CallPaymentSessionStatus.connected,
}) => CallPaymentDetailsData(
  session: CallPaymentSession(
    owner: activityOwner,
    callId: 'call-1',
    peerPubkey: 'b' * 64,
    direction: CallPaymentCallDirection.outgoing,
    role: role,
    callType: CallPaymentCallType.audio,
    status: status,
    mintUrl: activityMint,
    priceSatsPerMinute: 80,
    billingPeriodSeconds: 60,
    maxSpendSats: 100,
    connectedDurationSeconds: 12,
    chargedSats: 999,
    refundedSats: 0,
    connectedAt: activityTime,
    createdAt: activityTime,
    updatedAt: activityTime,
  ),
  installments: installments ?? [activityInstallment()],
);
