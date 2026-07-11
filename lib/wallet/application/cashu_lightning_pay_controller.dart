import '../domain/account_wallet.dart';
import '../domain/cashu_account_id.dart';
import '../domain/cashu_models.dart';
import '../domain/wallet_configuration.dart';
import '../domain/wallet_errors.dart';
import 'wallet_session_manager.dart';

final class CashuLightningPayMintOption {
  const CashuLightningPayMintOption({
    required this.mint,
    required this.balanceSats,
  });

  final MintConfiguration mint;
  final int balanceSats;
}

abstract interface class CashuLightningPayController {
  Future<List<CashuLightningPayMintOption>> loadPayOptions();

  Future<List<CashuLightningPayQuoteRecord>> loadQuoteRecords();

  Future<CashuMeltQuote> createQuote({
    required CashuMintUrl mintUrl,
    required String bolt11Invoice,
  });

  Future<CashuMeltResult> payQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  });
}

final class AccountCashuLightningPayController
    implements CashuLightningPayController {
  AccountCashuLightningPayController({
    required CashuAccountId accountId,
    required WalletSessionManager sessionManager,
    required MintConfigurationRepository mintRepository,
    required CashuLightningPayQuoteRepository quoteRepository,
    DateTime Function()? clock,
  }) : _accountId = accountId,
       _sessionManager = sessionManager,
       _mintRepository = mintRepository,
       _quoteRepository = quoteRepository,
       _clock = clock ?? DateTime.now;

  final CashuAccountId _accountId;
  final WalletSessionManager _sessionManager;
  final MintConfigurationRepository _mintRepository;
  final CashuLightningPayQuoteRepository _quoteRepository;
  final DateTime Function() _clock;

  @override
  Future<List<CashuLightningPayMintOption>> loadPayOptions() async {
    final wallet = await _requireWallet();
    final balances = await wallet.balancesByMintSats();
    final mints = await _mintRepository.list(_accountId);
    return List.unmodifiable(
      mints
          .where(_canPayLightning)
          .map(
            (mint) => CashuLightningPayMintOption(
              mint: mint,
              balanceSats: balances[mint.url] ?? 0,
            ),
          ),
    );
  }

  @override
  Future<List<CashuLightningPayQuoteRecord>> loadQuoteRecords() async {
    final records = await _quoteRepository.list(_accountId);
    final now = _clock();
    final restoredRecords = <CashuLightningPayQuoteRecord>[];
    for (final record in records) {
      final restoredRecord = _expireLocallyIfNeeded(record, now);
      if (restoredRecord.state != record.state) {
        await _quoteRepository.save(restoredRecord);
      }
      restoredRecords.add(restoredRecord);
    }
    return List.unmodifiable(restoredRecords);
  }

  @override
  Future<CashuMeltQuote> createQuote({
    required CashuMintUrl mintUrl,
    required String bolt11Invoice,
  }) async {
    final invoice = bolt11Invoice.trim();
    if (invoice.isEmpty) {
      throw ArgumentError.value(
        bolt11Invoice,
        'bolt11Invoice',
        'Lightning invoice cannot be empty',
      );
    }
    await _requireLightningPayMint(mintUrl);
    final wallet = await _requireWallet();
    final quote = await wallet.createMeltQuote(
      mintUrl: mintUrl,
      bolt11Invoice: invoice,
    );
    final balance = (await wallet.balancesByMintSats())[mintUrl] ?? 0;
    final requiredBalance = quote.amount.value + quote.feeReserve.value;
    if (balance < requiredBalance) {
      throw InsufficientCashuBalanceException(
        availableSats: balance,
        requestedSats: requiredBalance,
      );
    }
    await _quoteRepository.save(_recordFromQuote(quote, createdAt: _clock()));
    return quote;
  }

  @override
  Future<CashuMeltResult> payQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  }) async {
    await _requireLightningPayMint(mintUrl);
    await _requireLocallyPayableQuote(mintUrl: mintUrl, quoteId: quoteId);
    final result = await (await _requireWallet()).meltQuote(
      mintUrl: mintUrl,
      quoteId: quoteId,
    );
    await _savePaymentResult(result);
    return result;
  }

  Future<AccountWalletSession> _requireWallet() async {
    final session = await _sessionManager.activate(_accountId);
    final wallet = session.wallet;
    if (wallet == null) throw const WalletNotReadyException();
    return wallet;
  }

  Future<void> _requireLightningPayMint(CashuMintUrl mintUrl) async {
    final configuration = await _mintRepository.find(_accountId, mintUrl);
    if (configuration == null) throw UnknownMintException(mintUrl);
    if (!configuration.enabled) throw DisabledMintException(mintUrl);
    if (!_canPayLightning(configuration)) {
      throw UnsupportedMintException(
        supportsSat: configuration.units.contains('sat'),
        missingNutNumbers: {
          if (!configuration.supportedNuts.contains(CashuNut.nut05))
            CashuNut.nut05.number,
          if (!configuration.supportedNuts.contains(CashuNut.nut08))
            CashuNut.nut08.number,
          if (!configuration.supportedNuts.contains(CashuNut.nut23))
            CashuNut.nut23.number,
        },
      );
    }
  }

  bool _canPayLightning(MintConfiguration mint) =>
      mint.enabled &&
      mint.units.contains('sat') &&
      mint.supportedNuts.containsAll({
        CashuNut.nut05,
        CashuNut.nut08,
        CashuNut.nut23,
      });

  Future<void> _requireLocallyPayableQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  }) async {
    final record = await _quoteRepository.find(_accountId, quoteId);
    if (record == null) return;
    if (record.mintUrl != mintUrl) {
      throw const CashuProtocolException(
        'quote_mint_mismatch',
        'Payment quote does not belong to the selected Mint.',
      );
    }

    final restoredRecord = _expireLocallyIfNeeded(record, _clock());
    if (restoredRecord.state != record.state) {
      await _quoteRepository.save(restoredRecord);
    }
    if (!_canPayQuoteState(restoredRecord.state)) {
      throw CashuProtocolException(
        _payQuoteErrorCode(restoredRecord.state),
        _payQuoteErrorMessage(restoredRecord.state),
      );
    }
  }

  bool _canPayQuoteState(CashuQuoteState state) {
    return switch (state) {
      CashuQuoteState.unpaid || CashuQuoteState.pending => true,
      CashuQuoteState.paid ||
      CashuQuoteState.issued ||
      CashuQuoteState.expired ||
      CashuQuoteState.failed ||
      CashuQuoteState.unknown => false,
    };
  }

  String _payQuoteErrorCode(CashuQuoteState state) {
    return switch (state) {
      CashuQuoteState.expired => 'quote_expired',
      CashuQuoteState.paid || CashuQuoteState.issued => 'quote_already_paid',
      CashuQuoteState.failed => 'quote_failed',
      CashuQuoteState.unknown => 'quote_not_payable',
      CashuQuoteState.unpaid || CashuQuoteState.pending => 'quote_payable',
    };
  }

  String _payQuoteErrorMessage(CashuQuoteState state) {
    return switch (state) {
      CashuQuoteState.expired =>
        'Payment quote expired. Create a new quote before paying.',
      CashuQuoteState.paid ||
      CashuQuoteState.issued => 'Payment quote has already been paid.',
      CashuQuoteState.failed =>
        'Payment quote failed. Create a new quote before paying.',
      CashuQuoteState.unknown =>
        'Payment quote cannot be paid. Create a new quote before paying.',
      CashuQuoteState.unpaid ||
      CashuQuoteState.pending => 'Payment quote is ready.',
    };
  }

  CashuLightningPayQuoteRecord _expireLocallyIfNeeded(
    CashuLightningPayQuoteRecord record,
    DateTime now,
  ) {
    if (!_canPayQuoteState(record.state) || record.expiry.isAfter(now)) {
      return record;
    }
    return record.copyWith(state: CashuQuoteState.expired, updatedAt: now);
  }

  CashuLightningPayQuoteRecord _recordFromQuote(
    CashuMeltQuote quote, {
    required DateTime createdAt,
  }) {
    final now = _clock();
    return CashuLightningPayQuoteRecord(
      owner: _accountId,
      quoteId: quote.quoteId,
      mintUrl: quote.mintUrl,
      amount: quote.amount,
      request: quote.request,
      feeReserve: quote.feeReserve,
      state: quote.state,
      expiry: quote.expiry,
      createdAt: createdAt,
      updatedAt: now,
    );
  }

  Future<void> _savePaymentResult(CashuMeltResult result) async {
    final record = await _quoteRepository.find(_accountId, result.quoteId);
    if (record == null) return;
    await _quoteRepository.save(
      record.copyWith(
        state: result.state,
        updatedAt: _clock(),
        amountSpent: result.amountSpent,
        feePaid: result.feePaid,
        paymentPreimage: result.paymentPreimage,
      ),
    );
  }
}
