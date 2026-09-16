import 'package:noscall/core/common/database/db_isar.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import '../domain/call_payment_models.dart';
import '../domain/call_payment_summary.dart';
import '../infrastructure/isar_call_payment_repository.dart';

typedef CallPaymentDetailsLoader =
    Future<CallPaymentDetailsData?> Function(
      CashuAccountId owner,
      String callId,
    );

final class CallPaymentDetailsData {
  const CallPaymentDetailsData({
    required this.session,
    required this.installments,
  });
  final CallPaymentSession session;
  final List<CallPaymentInstallment> installments;
  CallPaymentSummary get summary =>
      CallPaymentSummary.fromInstallments(installments);

  static Future<CallPaymentDetailsData?> load(
    CashuAccountId owner,
    String callId,
  ) async {
    final isar = DBISAR.sharedInstance.isar;
    final session = await IsarCallPaymentSessionRepository(
      isar,
    ).find(owner, callId);
    if (session == null) return null;
    final installments = await IsarCallPaymentInstallmentRepository(
      isar,
    ).listForCall(owner: owner, callId: callId);
    return CallPaymentDetailsData(session: session, installments: installments);
  }
}
