import '../domain/cashu_account_id.dart';
import '../domain/cashu_models.dart';
import 'wallet_session_manager.dart';

final class AccountWalletBalanceService {
  AccountWalletBalanceService({
    required CashuAccountId accountId,
    required WalletSessionManager sessionManager,
  }) : _accountId = accountId,
       _sessionManager = sessionManager;

  final CashuAccountId _accountId;
  final WalletSessionManager _sessionManager;

  Future<Map<CashuMintUrl, int>> load() async {
    final session = await _sessionManager.activate(_accountId);
    final wallet = session.wallet;
    if (wallet == null) return const {};
    return wallet.balancesByMintSats();
  }

  Future<void> dispose() => _sessionManager.dispose();
}
