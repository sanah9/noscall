import 'cashu_models.dart';

abstract interface class CashuTokenCodec {
  CashuTokenSummary decodeToken(String encodedToken);
}

abstract interface class CashuMintInspector {
  Future<CashuMintSnapshot> inspectMint(CashuMintUrl mintUrl);
}

/// Protocol-neutral boundary around the selected Cashu implementation.
///
/// UI and application services must depend on this interface instead of a
/// concrete Dart or native Cashu SDK. Implementations own protocol-level
/// idempotency and must never treat a network timeout as a failed spend.
abstract interface class CashuEngine
    implements CashuTokenCodec, CashuMintInspector {
  String get implementationName;

  Set<CashuNut> get supportedNuts;

  Future<CashuReceiveResult> receive(CashuReceiveRequest request);

  Future<CashuPreparedSend> prepareSend(CashuSendRequest request);

  Future<CashuSendState> checkSendStatus(String operationId);

  Future<CashuAmount> reclaimSend(String operationId);

  Future<CashuMintQuote> createMintQuote({
    required CashuMintUrl mintUrl,
    required CashuAmount amount,
  });

  Future<CashuMintQuote> checkMintQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  });

  Future<CashuAmount> mint({
    required CashuMintUrl mintUrl,
    required String quoteId,
  });

  Future<CashuMeltQuote> createMeltQuote({
    required CashuMintUrl mintUrl,
    required String bolt11Invoice,
  });

  Future<CashuMeltResult> melt({
    required CashuMintUrl mintUrl,
    required String quoteId,
  });

  Future<CashuRestoreResult> restore({
    required String mnemonic,
    required List<CashuMintUrl> mintUrls,
  });

  Future<CashuReconciliationResult> reconcilePendingOperations();

  Future<void> close();
}
