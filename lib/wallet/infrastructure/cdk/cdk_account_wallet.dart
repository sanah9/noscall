import 'dart:io';

import 'package:cdk/cdk.dart' as cdk;
import 'package:crypto/crypto.dart';

import '../../domain/account_wallet.dart';
import '../../domain/cashu_account_id.dart';
import '../../domain/cashu_models.dart';
import '../../domain/wallet_key_store.dart';
import '../../domain/wallet_errors.dart';

final class CdkAccountWalletFactory implements AccountWalletFactory {
  CdkAccountWalletFactory({
    required this.walletsRoot,
    required this.keyStore,
    this.allowInsecureDevelopmentStore = false,
  });

  final Directory walletsRoot;
  final WalletKeyStore keyStore;
  final bool allowInsecureDevelopmentStore;

  @override
  Future<bool> exists(CashuAccountId accountId) async {
    _validateKeyStore();
    return await keyStore.readMnemonic(accountId.seedReference) != null;
  }

  @override
  Future<AccountWalletCreation<CdkAccountWallet>> createNew(
    CashuAccountId accountId,
  ) async {
    _validateKeyStore();
    final reference = accountId.seedReference;
    if (await keyStore.readMnemonic(reference) != null) {
      throw StateError('Cashu wallet already exists for this account');
    }

    final mnemonic = cdk.generateMnemonic();
    _validateTwelveWordMnemonic(mnemonic);

    // Persist before opening SQLite. If process startup fails after this point,
    // the same seed remains available and openExisting can safely retry.
    await keyStore.writeMnemonic(reference, mnemonic);
    final wallet = await _open(accountId, mnemonic);
    return AccountWalletCreation(wallet: wallet, mnemonic: mnemonic);
  }

  @override
  Future<CdkAccountWallet> openExisting(CashuAccountId accountId) async {
    _validateKeyStore();
    final mnemonic = await keyStore.readMnemonic(accountId.seedReference);
    if (mnemonic == null) {
      throw StateError('Cashu wallet does not exist for this account');
    }
    _validateTwelveWordMnemonic(mnemonic);
    return _open(accountId, mnemonic);
  }

  Future<CdkAccountWallet> _open(
    CashuAccountId accountId,
    String mnemonic,
  ) async {
    final accountDirectory = Directory(
      '${walletsRoot.path}/${accountId.value}',
    );
    await accountDirectory.create(recursive: true);
    final databaseFile = File('${accountDirectory.path}/cdk.sqlite3');
    final repository = cdk.WalletRepository(
      mnemonic: mnemonic,
      store: cdk.SqliteWalletStore(databaseFile.path),
    );
    return CdkAccountWallet._(
      accountId: accountId,
      databaseFile: databaseFile,
      repository: repository,
    );
  }

  void _validateKeyStore() {
    if (!keyStore.isProductionReady && !allowInsecureDevelopmentStore) {
      throw StateError(
        'Development WalletKeyStore requires explicit insecure opt-in',
      );
    }
  }

  void _validateTwelveWordMnemonic(String mnemonic) {
    final words = mnemonic.trim().split(RegExp(r'\s+'));
    if (words.length != 12 ||
        cdk.mnemonicToEntropy(mnemonic: mnemonic).length != 16) {
      throw const FormatException('Cashu wallet requires a 12-word mnemonic');
    }
  }
}

final class CdkAccountWallet implements AccountWalletSession {
  CdkAccountWallet._({
    required this.accountId,
    required this.databaseFile,
    required cdk.WalletRepository repository,
  }) : _repository = repository;

  @override
  final CashuAccountId accountId;
  final File databaseFile;
  final cdk.WalletRepository _repository;
  final Map<CashuMintUrl, cdk.Wallet> _wallets = {};
  bool _closed = false;

  Future<bool> hasMint(CashuMintUrl mintUrl) {
    _ensureOpen();
    return _repository.hasMint(mintUrl: cdk.MintUrl(url: mintUrl.toString()));
  }

  /// Adds a sat-denominated Mint only when explicitly requested by the user.
  /// No default Mint is created when the account wallet opens.
  Future<cdk.Wallet> addOrOpenMint(CashuMintUrl mintUrl) async {
    _ensureOpen();
    final cached = _wallets[mintUrl];
    if (cached != null) return cached;

    final cdkUrl = cdk.MintUrl(url: mintUrl.toString());
    if (!await _repository.hasMint(mintUrl: cdkUrl)) {
      await _repository.createWallet(
        mintUrl: cdkUrl,
        unit: cdk.SatCurrencyUnit(),
        targetProofCount: null,
      );
    }
    final wallet = await _repository.getWallet(
      mintUrl: cdkUrl,
      unit: cdk.SatCurrencyUnit(),
    );
    _wallets[mintUrl] = wallet;
    return wallet;
  }

  @override
  Future<int> totalBalanceSats() async {
    final balances = await balancesByMintSats();
    return balances.values.fold<int>(0, (total, amount) => total + amount);
  }

  @override
  Future<Map<CashuMintUrl, int>> balancesByMintSats() async {
    _ensureOpen();
    final balances = await _repository.getBalances();
    final result = <CashuMintUrl, int>{};
    for (final entry in balances.entries) {
      if (entry.key.unit is! cdk.SatCurrencyUnit) continue;
      final url = CashuMintUrl.parse(entry.key.mintUrl.url);
      result[url] = (result[url] ?? 0) + entry.value.value;
    }
    return Map.unmodifiable(result);
  }

  @override
  Future<CashuReceiveResult> receive(CashuReceiveRequest request) async {
    _ensureOpen();
    cdk.Token? token;
    try {
      final encodedToken = request.encodedToken.trim();
      token = cdk.Token.decode(encodedToken: encodedToken);
      if (token.unit() is! cdk.SatCurrencyUnit) {
        throw const CashuProtocolException(
          'unsupported_unit',
          'Only sat-denominated Cashu tokens are supported',
        );
      }
      final mintUrl = CashuMintUrl.parse(token.mintUrl().url);
      final wallet = await addOrOpenMint(mintUrl);
      final amount = await wallet.receive(
        token: token,
        options: _receiveOptions(),
      );
      return CashuReceiveResult(
        operationId: _localReceiveOperationId(encodedToken),
        amount: CashuAmount.positiveSats(amount.value),
      );
    } on CashuProtocolException {
      rethrow;
    } on FormatException {
      throw const CashuProtocolException(
        'invalid_mint_url',
        'The token contains an invalid or insecure Mint URL',
      );
    } on cdk.FfiException {
      throw const CashuProtocolException(
        'receive_failed',
        'The Cashu token could not be received',
      );
    } finally {
      token?.dispose();
    }
  }

  @override
  Future<CashuPreparedSend> prepareSend(CashuSendRequest request) async {
    _ensureOpen();
    if (request.amount.value <= 0) {
      throw ArgumentError.value(
        request.amount.value,
        'amount',
        'Send amount must be positive',
      );
    }
    cdk.PreparedSend? prepared;
    cdk.Token? token;
    try {
      final wallet = await addOrOpenMint(request.mintUrl);
      prepared = await wallet.prepareSend(
        amount: cdk.Amount(value: request.amount.value),
        options: _sendOptions(request.memo),
      );
      final operationId = prepared.operationId();
      token = await prepared.confirm(memo: _normalizedMemo(request.memo));
      return CashuPreparedSend(
        operationId: operationId,
        token: token.encode(),
        amount: CashuAmount.positiveSats(prepared.amount().value),
      );
    } on cdk.FfiException {
      throw const CashuProtocolException(
        'send_failed',
        'The Cashu token could not be prepared',
      );
    } finally {
      token?.dispose();
      prepared?.dispose();
    }
  }

  @override
  Future<CashuSendState> checkSendStatus({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) async {
    _ensureOpen();
    try {
      final wallet = await addOrOpenMint(mintUrl);
      final claimed = await wallet.checkSendStatus(operationId: operationId);
      return claimed ? CashuSendState.claimed : CashuSendState.recoverable;
    } on cdk.FfiException {
      throw const CashuProtocolException(
        'send_status_failed',
        'The Cashu send status could not be checked',
      );
    }
  }

  @override
  Future<CashuAmount> reclaimSend({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) async {
    _ensureOpen();
    try {
      final wallet = await addOrOpenMint(mintUrl);
      final amount = await wallet.revokeSend(operationId: operationId);
      return CashuAmount.sats(amount.value);
    } on cdk.FfiException {
      throw const CashuProtocolException(
        'reclaim_failed',
        'The Cashu send could not be reclaimed',
      );
    }
  }

  @override
  Future<CashuMintQuote> createMintQuote({
    required CashuMintUrl mintUrl,
    required CashuAmount amount,
  }) async {
    _ensureOpen();
    if (amount.value <= 0) {
      throw ArgumentError.value(
        amount.value,
        'amount',
        'Mint quote amount must be positive',
      );
    }
    try {
      final wallet = await addOrOpenMint(mintUrl);
      final quote = await wallet.mintQuote(
        paymentMethod: cdk.Bolt11PaymentMethod(),
        amount: cdk.Amount(value: amount.value),
        description: null,
        extra: null,
      );
      return _mintQuoteFromCdk(quote);
    } on cdk.FfiException {
      throw const CashuProtocolException(
        'mint_quote_failed',
        'The Lightning receive quote could not be created',
      );
    }
  }

  @override
  Future<CashuMintQuote> checkMintQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  }) async {
    _ensureOpen();
    try {
      final wallet = await addOrOpenMint(mintUrl);
      final quote = await wallet.checkMintQuote(quoteId: quoteId);
      return _mintQuoteFromCdk(quote);
    } on cdk.FfiException {
      throw const CashuProtocolException(
        'mint_quote_status_failed',
        'The Lightning receive quote status could not be checked',
      );
    }
  }

  @override
  Future<CashuAmount> mintQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  }) async {
    _ensureOpen();
    try {
      final wallet = await addOrOpenMint(mintUrl);
      final proofs = await wallet.mint(
        quoteId: quoteId,
        amountSplitTarget: cdk.NoneSplitTarget(),
        spendingConditions: null,
      );
      final amount = cdk.proofsTotalAmount(proofs: proofs);
      return CashuAmount.sats(amount.value);
    } on cdk.FfiException {
      throw const CashuProtocolException(
        'mint_failed',
        'The Lightning receive quote could not be minted',
      );
    }
  }

  @override
  Future<CashuMeltQuote> createMeltQuote({
    required CashuMintUrl mintUrl,
    required String bolt11Invoice,
  }) async {
    _ensureOpen();
    final invoice = bolt11Invoice.trim();
    if (invoice.isEmpty) {
      throw ArgumentError.value(
        bolt11Invoice,
        'bolt11Invoice',
        'Lightning invoice cannot be empty',
      );
    }
    try {
      final wallet = await addOrOpenMint(mintUrl);
      final quote = await wallet.meltQuote(
        method: cdk.Bolt11PaymentMethod(),
        request: invoice,
        options: null,
        extra: null,
      );
      return _meltQuoteFromCdk(quote, fallbackMintUrl: mintUrl);
    } on cdk.FfiException {
      throw const CashuProtocolException(
        'melt_quote_failed',
        'The Lightning pay quote could not be created',
      );
    }
  }

  @override
  Future<CashuMeltResult> meltQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  }) async {
    _ensureOpen();
    cdk.PreparedMelt? prepared;
    try {
      final wallet = await addOrOpenMint(mintUrl);
      prepared = await wallet.prepareMelt(quoteId: quoteId);
      final finalized = await prepared.confirm();
      return _meltResultFromCdk(finalized);
    } on cdk.FfiException {
      throw const CashuProtocolException(
        'melt_failed',
        'The Lightning invoice could not be paid',
      );
    } finally {
      prepared?.dispose();
    }
  }

  @override
  Future<CashuReconciliationResult> reconcilePendingOperations() async {
    _ensureOpen();
    var recovered = 0;
    var pending = 0;
    final wallets = await _repository.getWallets();
    try {
      for (final wallet in wallets) {
        final report = await wallet.recoverIncompleteSagas();
        recovered += report.recovered + report.compensated;

        await wallet.checkAllPendingProofs();
        final pendingSends = await wallet.getPendingSends();
        for (final operationId in pendingSends) {
          await wallet.checkSendStatus(operationId: operationId);
        }
        pending +=
            (await wallet.getPendingSends()).length +
            report.skipped +
            report.failed;
      }
    } finally {
      for (final wallet in wallets) {
        wallet.dispose();
      }
    }
    return CashuReconciliationResult(
      recoveredOperations: recovered,
      pendingOperations: pending,
    );
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    for (final wallet in _wallets.values) {
      wallet.dispose();
    }
    _wallets.clear();
    _repository.dispose();
  }

  void _ensureOpen() {
    if (_closed) throw StateError('Cashu wallet session is closed');
  }

  cdk.ReceiveOptions _receiveOptions() => cdk.ReceiveOptions(
    amountSplitTarget: cdk.NoneSplitTarget(),
    p2pkSigningKeys: const [],
    preimages: const [],
    metadata: const {},
  );

  cdk.SendOptions _sendOptions(String? memo) {
    final normalizedMemo = _normalizedMemo(memo);
    return cdk.SendOptions(
      memo: normalizedMemo == null
          ? null
          : cdk.SendMemo(memo: normalizedMemo, includeMemo: true),
      conditions: null,
      amountSplitTarget: cdk.NoneSplitTarget(),
      sendKind: cdk.OnlineExactSendKind(),
      includeFee: true,
      useP2bk: false,
      maxProofs: null,
      metadata: const {},
      p2pkSigningKeys: const [],
      p2pkLockedProofSendMode: cdk.P2pkLockedProofSendMode.swap,
    );
  }

  String? _normalizedMemo(String? memo) {
    final trimmed = memo?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String _localReceiveOperationId(String encodedToken) {
    final digest = sha256.convert(encodedToken.codeUnits).toString();
    return 'receive:${digest.substring(0, 16)}';
  }

  CashuMintQuote _mintQuoteFromCdk(cdk.MintQuote quote) {
    if (quote.unit is! cdk.SatCurrencyUnit) {
      throw const CashuProtocolException(
        'unsupported_unit',
        'Only sat-denominated Lightning receive quotes are supported',
      );
    }
    return CashuMintQuote(
      quoteId: quote.id,
      mintUrl: CashuMintUrl.parse(quote.mintUrl.url),
      amount: CashuAmount.sats(quote.amount?.value ?? quote.amountPaid.value),
      request: quote.request,
      state: _isExpired(quote)
          ? CashuQuoteState.expired
          : _quoteStateFromCdk(quote.state),
      expiry: DateTime.fromMillisecondsSinceEpoch(
        quote.expiry * 1000,
        isUtc: true,
      ),
    );
  }

  CashuMeltQuote _meltQuoteFromCdk(
    cdk.MeltQuote quote, {
    required CashuMintUrl fallbackMintUrl,
  }) {
    if (quote.unit is! cdk.SatCurrencyUnit) {
      throw const CashuProtocolException(
        'unsupported_unit',
        'Only sat-denominated Lightning pay quotes are supported',
      );
    }
    return CashuMeltQuote(
      quoteId: quote.id,
      mintUrl: quote.mintUrl == null
          ? fallbackMintUrl
          : CashuMintUrl.parse(quote.mintUrl!.url),
      amount: CashuAmount.sats(quote.amount.value),
      feeReserve: CashuAmount.sats(quote.feeReserve.value),
      state: _isMeltQuoteExpired(quote)
          ? CashuQuoteState.expired
          : _quoteStateFromCdk(quote.state),
      expiry: DateTime.fromMillisecondsSinceEpoch(
        quote.expiry * 1000,
        isUtc: true,
      ),
    );
  }

  CashuMeltResult _meltResultFromCdk(cdk.FinalizedMelt melt) {
    final amount = CashuAmount.sats(melt.amount.value);
    final feePaid = CashuAmount.sats(melt.feePaid.value);
    return CashuMeltResult(
      quoteId: melt.quoteId,
      state: _quoteStateFromCdk(melt.state),
      amountSpent: amount + feePaid,
      feePaid: feePaid,
      paymentPreimage: melt.preimage,
    );
  }

  bool _isExpired(cdk.MintQuote quote) {
    if (quote.state == cdk.QuoteState.issued) return false;
    return cdk.mintQuoteIsExpired(
      quote: quote,
      currentTime: DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
    );
  }

  bool _isMeltQuoteExpired(cdk.MeltQuote quote) {
    if (quote.state == cdk.QuoteState.issued ||
        quote.state == cdk.QuoteState.paid) {
      return false;
    }
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return quote.expiry <= now;
  }

  CashuQuoteState _quoteStateFromCdk(cdk.QuoteState state) {
    return switch (state) {
      cdk.QuoteState.unpaid => CashuQuoteState.unpaid,
      cdk.QuoteState.pending => CashuQuoteState.pending,
      cdk.QuoteState.paid => CashuQuoteState.paid,
      cdk.QuoteState.issued => CashuQuoteState.issued,
    };
  }
}
