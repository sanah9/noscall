import 'cashu_account_id.dart';
import 'cashu_models.dart';

/// Protocol-neutral session for one Nostr account's Cashu wallet.
abstract interface class AccountWalletSession {
  CashuAccountId get accountId;

  Future<int> totalBalanceSats();

  Future<Map<CashuMintUrl, int>> balancesByMintSats();

  Future<CashuReceiveResult> receive(CashuReceiveRequest request);

  Future<CashuPreparedSend> prepareSend(CashuSendRequest request);

  Future<CashuSendState> checkSendStatus({
    required CashuMintUrl mintUrl,
    required String operationId,
  });

  Future<CashuAmount> reclaimSend({
    required CashuMintUrl mintUrl,
    required String operationId,
  });

  Future<CashuMintQuote> createMintQuote({
    required CashuMintUrl mintUrl,
    required CashuAmount amount,
  });

  Future<CashuMintQuote> checkMintQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  });

  Future<CashuAmount> mintQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  });

  Future<CashuReconciliationResult> reconcilePendingOperations();

  Future<void> close();
}

/// Result of creating a wallet. The mnemonic is intentionally returned only
/// for the backup flow and must never be logged.
final class AccountWalletCreation<T extends AccountWalletSession> {
  const AccountWalletCreation({required this.wallet, required this.mnemonic});

  final T wallet;
  final String mnemonic;
}

/// Boundary used by application services; concrete SDK types stay below it.
abstract interface class AccountWalletFactory {
  Future<bool> exists(CashuAccountId accountId);

  Future<AccountWalletCreation<AccountWalletSession>> createNew(
    CashuAccountId accountId,
  );

  Future<AccountWalletSession> openExisting(CashuAccountId accountId);
}
