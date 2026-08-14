import 'package:noscall/wallet/domain/cashu_account_id.dart';

import 'call_payment_models.dart';

abstract interface class CallPaymentPolicyRepository {
  Future<CallPaymentPolicy?> find(CashuAccountId owner);

  Future<void> save(CallPaymentPolicy policy);
}

abstract interface class CallPaymentSessionRepository {
  Future<CallPaymentSession?> find(CashuAccountId owner, String callId);

  Future<List<CallPaymentSession>> list(CashuAccountId owner);

  Future<void> save(CallPaymentSession session);
}

abstract interface class CallPaymentInstallmentRepository {
  Future<CallPaymentInstallment?> find({
    required CashuAccountId owner,
    required String callId,
    required int sequence,
    required CallPaymentPurpose purpose,
    required CallPaymentTransferDirection direction,
  });

  Future<CallPaymentInstallment?> findByWalletOperationId({
    required CashuAccountId owner,
    required String walletOperationId,
  });

  Future<List<CallPaymentInstallment>> listForCall({
    required CashuAccountId owner,
    required String callId,
  });

  Future<void> save(CallPaymentInstallment installment);
}
