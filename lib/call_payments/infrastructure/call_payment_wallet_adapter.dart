import 'package:noscall/call_payments/application/call_payment_incoming_transfer_service.dart';
import 'package:noscall/call_payments/application/call_payment_initial_payment_service.dart';
import 'package:noscall/call_payments/application/call_payment_recovery_service.dart';
import 'package:noscall/call_payments/application/call_payment_start_guard.dart';
import 'package:noscall/wallet/domain/account_wallet.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

final class AccountWalletCallPaymentAdapter
    implements
        CallPaymentTokenSender,
        CallPaymentTokenReceiver,
        CallPaymentTokenRecoverer {
  const AccountWalletCallPaymentAdapter(this._wallet);

  final AccountWalletSession _wallet;

  CallPaymentBalanceLoader get loadBalancesByMintSats =>
      _wallet.balancesByMintSats;

  Future<Map<CashuMintUrl, int>> call() {
    return _wallet.balancesByMintSats();
  }

  @override
  Future<CashuPreparedSend> prepareSend({
    required CashuMintUrl mintUrl,
    required CashuAmount amount,
    String? memo,
  }) {
    return _wallet.prepareSend(
      CashuSendRequest(mintUrl: mintUrl, amount: amount, memo: memo),
    );
  }

  @override
  Future<CashuReceiveResult> receive(String encodedToken) {
    return _wallet.receive(CashuReceiveRequest(encodedToken: encodedToken));
  }

  @override
  Future<CashuSendState> checkSendStatus({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) {
    return _wallet.checkSendStatus(mintUrl: mintUrl, operationId: operationId);
  }

  @override
  Future<CashuAmount> reclaimSend({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) {
    return _wallet.reclaimSend(mintUrl: mintUrl, operationId: operationId);
  }
}
