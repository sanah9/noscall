import '../domain/account_wallet.dart';
import '../domain/cashu_account_id.dart';
import '../domain/cashu_models.dart';
import '../domain/wallet_configuration.dart';
import '../domain/wallet_errors.dart';
import 'wallet_session_manager.dart';

final class CashuLightningReceiveMintOption {
  const CashuLightningReceiveMintOption({required this.mint});

  final MintConfiguration mint;
}

abstract interface class CashuLightningReceiveController {
  Future<List<CashuLightningReceiveMintOption>> loadReceiveOptions();

  Future<List<CashuLightningReceiveQuoteRecord>> loadQuoteRecords();

  Future<CashuMintQuote> createQuote({
    required CashuMintUrl mintUrl,
    required CashuAmount amount,
  });

  Future<CashuMintQuote> checkQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  });

  Future<CashuAmount> mintQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  });
}

final class AccountCashuLightningReceiveController
    implements CashuLightningReceiveController {
  AccountCashuLightningReceiveController({
    required CashuAccountId accountId,
    required WalletSessionManager sessionManager,
    required MintConfigurationRepository mintRepository,
    required CashuLightningReceiveQuoteRepository quoteRepository,
    DateTime Function()? clock,
  }) : _accountId = accountId,
       _sessionManager = sessionManager,
       _mintRepository = mintRepository,
       _quoteRepository = quoteRepository,
       _clock = clock ?? DateTime.now;

  final CashuAccountId _accountId;
  final WalletSessionManager _sessionManager;
  final MintConfigurationRepository _mintRepository;
  final CashuLightningReceiveQuoteRepository _quoteRepository;
  final DateTime Function() _clock;

  @override
  Future<List<CashuLightningReceiveMintOption>> loadReceiveOptions() async {
    final mints = await _mintRepository.list(_accountId);
    return List.unmodifiable(
      mints
          .where(_canReceiveLightning)
          .map((mint) => CashuLightningReceiveMintOption(mint: mint)),
    );
  }

  @override
  Future<List<CashuLightningReceiveQuoteRecord>> loadQuoteRecords() =>
      _quoteRepository.list(_accountId);

  @override
  Future<CashuMintQuote> createQuote({
    required CashuMintUrl mintUrl,
    required CashuAmount amount,
  }) async {
    if (amount.value <= 0) {
      throw ArgumentError.value(
        amount.value,
        'amount',
        'Lightning receive amount must be positive',
      );
    }
    await _requireLightningReceiveMint(mintUrl);
    final quote = await (await _requireWallet()).createMintQuote(
      mintUrl: mintUrl,
      amount: amount,
    );
    await _quoteRepository.save(_recordFromQuote(quote, createdAt: _clock()));
    return quote;
  }

  @override
  Future<CashuMintQuote> checkQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  }) async {
    await _requireLightningReceiveMint(mintUrl);
    final quote = await (await _requireWallet()).checkMintQuote(
      mintUrl: mintUrl,
      quoteId: quoteId,
    );
    await _saveQuoteUpdate(quote);
    return quote;
  }

  @override
  Future<CashuAmount> mintQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  }) async {
    await _requireLightningReceiveMint(mintUrl);
    final amount = await (await _requireWallet()).mintQuote(
      mintUrl: mintUrl,
      quoteId: quoteId,
    );
    await _updateQuoteState(quoteId, CashuQuoteState.issued);
    return amount;
  }

  Future<AccountWalletSession> _requireWallet() async {
    final session = await _sessionManager.activate(_accountId);
    final wallet = session.wallet;
    if (wallet == null) throw const WalletNotReadyException();
    return wallet;
  }

  Future<void> _requireLightningReceiveMint(CashuMintUrl mintUrl) async {
    final configuration = await _mintRepository.find(_accountId, mintUrl);
    if (configuration == null) throw UnknownMintException(mintUrl);
    if (!configuration.enabled) throw DisabledMintException(mintUrl);
    if (!_canReceiveLightning(configuration)) {
      throw UnsupportedMintException(
        supportsSat: configuration.units.contains('sat'),
        missingNutNumbers: {
          if (!configuration.supportedNuts.contains(CashuNut.nut04))
            CashuNut.nut04.number,
          if (!configuration.supportedNuts.contains(CashuNut.nut23))
            CashuNut.nut23.number,
        },
      );
    }
  }

  bool _canReceiveLightning(MintConfiguration mint) =>
      mint.enabled &&
      mint.units.contains('sat') &&
      mint.supportedNuts.containsAll({CashuNut.nut04, CashuNut.nut23});

  Future<void> _saveQuoteUpdate(CashuMintQuote quote) async {
    final existing = await _quoteRepository.find(_accountId, quote.quoteId);
    await _quoteRepository.save(
      _recordFromQuote(quote, createdAt: existing?.createdAt ?? _clock()),
    );
  }

  Future<void> _updateQuoteState(String quoteId, CashuQuoteState state) async {
    final record = await _quoteRepository.find(_accountId, quoteId);
    if (record == null) return;
    await _quoteRepository.save(
      record.copyWith(state: state, updatedAt: _clock()),
    );
  }

  CashuLightningReceiveQuoteRecord _recordFromQuote(
    CashuMintQuote quote, {
    required DateTime createdAt,
  }) {
    final now = _clock();
    return CashuLightningReceiveQuoteRecord(
      owner: _accountId,
      quoteId: quote.quoteId,
      mintUrl: quote.mintUrl,
      amount: quote.amount,
      request: quote.request,
      state: quote.state,
      expiry: quote.expiry,
      createdAt: createdAt,
      updatedAt: now,
    );
  }
}
