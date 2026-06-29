import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/application/cashu_lightning_receive_controller.dart';
import 'package:noscall/wallet/application/wallet_session_manager.dart';
import 'package:noscall/wallet/domain/account_wallet.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';
import 'package:noscall/wallet/domain/wallet_configuration.dart';
import 'package:noscall/wallet/domain/wallet_errors.dart';

void main() {
  late CashuAccountId account;
  late CashuMintUrl mintUrl;
  late CashuMintUrl unsupportedMintUrl;
  late _MintRepository mintRepository;
  late _QuoteRepository quoteRepository;
  late _Wallet wallet;
  late AccountCashuLightningReceiveController controller;

  setUp(() {
    account = CashuAccountId.fromNostrPubkey('a' * 64);
    mintUrl = CashuMintUrl.parse('https://mint.example.com');
    unsupportedMintUrl = CashuMintUrl.parse('https://token-only.example.com');
    mintRepository = _MintRepository();
    quoteRepository = _QuoteRepository();
    wallet = _Wallet(account);
    controller = AccountCashuLightningReceiveController(
      accountId: account,
      sessionManager: WalletSessionManager(factory: _WalletFactory(wallet)),
      mintRepository: mintRepository,
      quoteRepository: quoteRepository,
      clock: () => DateTime.utc(2026, 6, 29, 12),
    );
  });

  test('lists only enabled Mints that support Lightning receive', () async {
    mintRepository
      ..put(_mint(account, mintUrl))
      ..put(_mint(account, unsupportedMintUrl, supportsLightningReceive: false))
      ..put(
        _mint(
          account,
          CashuMintUrl.parse('https://disabled.example.com'),
          enabled: false,
        ),
      )
      ..put(
        _mint(
          CashuAccountId.fromNostrPubkey('b' * 64),
          CashuMintUrl.parse('https://other.example.com'),
        ),
      );

    final options = await controller.loadReceiveOptions();

    expect(options.map((option) => option.mint.url), [mintUrl]);
  });

  test('creates, checks, and mints a Lightning receive quote', () async {
    mintRepository.put(_mint(account, mintUrl));

    final quote = await controller.createQuote(
      mintUrl: mintUrl,
      amount: CashuAmount.positiveSats(21),
    );
    final status = await controller.checkQuote(
      mintUrl: mintUrl,
      quoteId: quote.quoteId,
    );
    final amount = await controller.mintQuote(
      mintUrl: mintUrl,
      quoteId: quote.quoteId,
    );

    expect(quote.quoteId, 'quote-1');
    expect(quote.request, 'lnbc210n1test');
    expect(quote.state, CashuQuoteState.unpaid);
    expect(status.state, CashuQuoteState.paid);
    expect(amount, CashuAmount.sats(21));
    expect(wallet.createdQuoteAmounts, [21]);
    expect(wallet.checkedQuoteIds, ['quote-1']);
    expect(wallet.mintedQuoteIds, ['quote-1']);
    expect(
      (await quoteRepository.find(account, 'quote-1'))?.state,
      CashuQuoteState.issued,
    );
    expect(
      (await quoteRepository.find(account, 'quote-1'))?.request,
      'lnbc210n1test',
    );
    expect(await controller.loadQuoteRecords(), hasLength(1));
  });

  test(
    'rejects unsupported and non-positive Lightning receive requests',
    () async {
      mintRepository.put(
        _mint(account, unsupportedMintUrl, supportsLightningReceive: false),
      );

      await expectLater(
        controller.createQuote(
          mintUrl: unsupportedMintUrl,
          amount: CashuAmount.positiveSats(21),
        ),
        throwsA(isA<UnsupportedMintException>()),
      );
      await expectLater(
        controller.createQuote(
          mintUrl: unsupportedMintUrl,
          amount: CashuAmount.sats(0),
        ),
        throwsArgumentError,
      );
    },
  );
}

MintConfiguration _mint(
  CashuAccountId owner,
  CashuMintUrl url, {
  bool enabled = true,
  bool supportsLightningReceive = true,
}) => MintConfiguration(
  owner: owner,
  url: url,
  enabled: enabled,
  source: MintConfigurationSource.manual,
  supportedNuts: {
    CashuNut.nut00,
    CashuNut.nut01,
    CashuNut.nut02,
    CashuNut.nut03,
    CashuNut.nut06,
    CashuNut.nut07,
    CashuNut.nut09,
    if (supportsLightningReceive) CashuNut.nut04,
    if (supportsLightningReceive) CashuNut.nut23,
  },
  units: const ['sat'],
  lastSyncAt: DateTime.utc(2026, 6, 29),
);

final class _MintRepository implements MintConfigurationRepository {
  final Map<String, MintConfiguration> values = {};

  void put(MintConfiguration configuration) {
    values[_key(configuration.owner, configuration.url)] = configuration;
  }

  String _key(CashuAccountId owner, CashuMintUrl url) =>
      '${owner.value}|${url.toString()}';

  @override
  Future<void> delete(CashuAccountId owner, CashuMintUrl url) async {
    values.remove(_key(owner, url));
  }

  @override
  Future<MintConfiguration?> find(
    CashuAccountId owner,
    CashuMintUrl url,
  ) async => values[_key(owner, url)];

  @override
  Future<List<MintConfiguration>> list(CashuAccountId owner) async => values
      .values
      .where((configuration) => configuration.owner == owner)
      .toList(growable: false);

  @override
  Future<void> save(MintConfiguration configuration) async =>
      put(configuration);
}

final class _QuoteRepository implements CashuLightningReceiveQuoteRepository {
  final Map<String, CashuLightningReceiveQuoteRecord> values = {};

  String _key(CashuAccountId owner, String quoteId) =>
      '${owner.value}|$quoteId';

  @override
  Future<CashuLightningReceiveQuoteRecord?> find(
    CashuAccountId owner,
    String quoteId,
  ) async => values[_key(owner, quoteId)];

  @override
  Future<List<CashuLightningReceiveQuoteRecord>> list(
    CashuAccountId owner,
  ) async => values.values
      .where((record) => record.owner == owner)
      .toList(growable: false);

  @override
  Future<void> save(CashuLightningReceiveQuoteRecord record) async {
    values[_key(record.owner, record.quoteId)] = record;
  }
}

final class _WalletFactory implements AccountWalletFactory {
  const _WalletFactory(this.wallet);

  final _Wallet wallet;

  @override
  Future<bool> exists(CashuAccountId accountId) async => true;

  @override
  Future<AccountWalletSession> openExisting(CashuAccountId accountId) async =>
      wallet;

  @override
  Future<AccountWalletCreation<AccountWalletSession>> createNew(
    CashuAccountId accountId,
  ) => throw UnimplementedError();
}

final class _Wallet implements AccountWalletSession {
  _Wallet(this.accountId);

  @override
  final CashuAccountId accountId;
  final List<int> createdQuoteAmounts = [];
  final List<String> checkedQuoteIds = [];
  final List<String> mintedQuoteIds = [];

  @override
  Future<CashuMintQuote> createMintQuote({
    required CashuMintUrl mintUrl,
    required CashuAmount amount,
  }) async {
    createdQuoteAmounts.add(amount.value);
    return _quote(mintUrl, state: CashuQuoteState.unpaid);
  }

  @override
  Future<CashuMintQuote> checkMintQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  }) async {
    checkedQuoteIds.add(quoteId);
    return _quote(mintUrl, state: CashuQuoteState.paid);
  }

  @override
  Future<CashuAmount> mintQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  }) async {
    mintedQuoteIds.add(quoteId);
    return CashuAmount.sats(21);
  }

  CashuMintQuote _quote(
    CashuMintUrl mintUrl, {
    required CashuQuoteState state,
  }) {
    return CashuMintQuote(
      quoteId: 'quote-1',
      mintUrl: mintUrl,
      amount: CashuAmount.sats(21),
      request: 'lnbc210n1test',
      state: state,
      expiry: DateTime.utc(2026, 6, 29, 12),
    );
  }

  @override
  Future<Map<CashuMintUrl, int>> balancesByMintSats() async => const {};

  @override
  Future<CashuReceiveResult> receive(CashuReceiveRequest request) =>
      throw UnimplementedError();

  @override
  Future<CashuPreparedSend> prepareSend(CashuSendRequest request) =>
      throw UnimplementedError();

  @override
  Future<CashuSendState> checkSendStatus({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) => throw UnimplementedError();

  @override
  Future<CashuAmount> reclaimSend({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) => throw UnimplementedError();

  @override
  Future<CashuReconciliationResult> reconcilePendingOperations() async =>
      const CashuReconciliationResult(
        recoveredOperations: 0,
        pendingOperations: 0,
      );

  @override
  Future<int> totalBalanceSats() async => 0;

  @override
  Future<void> close() async {}
}
