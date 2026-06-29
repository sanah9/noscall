import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/application/cashu_lightning_pay_controller.dart';
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
  late _Wallet wallet;
  late AccountCashuLightningPayController controller;

  setUp(() {
    account = CashuAccountId.fromNostrPubkey('a' * 64);
    mintUrl = CashuMintUrl.parse('https://mint.example.com');
    unsupportedMintUrl = CashuMintUrl.parse('https://receive-only.example.com');
    mintRepository = _MintRepository();
    wallet = _Wallet(account, balances: {mintUrl: 100});
    controller = AccountCashuLightningPayController(
      accountId: account,
      sessionManager: WalletSessionManager(factory: _WalletFactory(wallet)),
      mintRepository: mintRepository,
    );
  });

  test('lists only enabled Mints that support Lightning pay', () async {
    mintRepository
      ..put(_mint(account, mintUrl))
      ..put(_mint(account, unsupportedMintUrl, supportsLightningPay: false))
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

    final options = await controller.loadPayOptions();

    expect(options.map((option) => option.mint.url), [mintUrl]);
    expect(options.single.balanceSats, 100);
  });

  test('creates quote and pays a Lightning invoice', () async {
    mintRepository.put(_mint(account, mintUrl));

    final quote = await controller.createQuote(
      mintUrl: mintUrl,
      bolt11Invoice: ' lnbc420n1test ',
    );
    final result = await controller.payQuote(
      mintUrl: mintUrl,
      quoteId: quote.quoteId,
    );

    expect(quote.quoteId, 'melt-quote-1');
    expect(quote.amount, CashuAmount.sats(42));
    expect(quote.feeReserve, CashuAmount.sats(2));
    expect(result.quoteId, 'melt-quote-1');
    expect(result.state, CashuQuoteState.paid);
    expect(result.amountSpent, CashuAmount.sats(43));
    expect(result.feePaid, CashuAmount.sats(1));
    expect(result.paymentPreimage, 'preimage');
    expect(wallet.createdInvoices, ['lnbc420n1test']);
    expect(wallet.paidQuoteIds, ['melt-quote-1']);
  });

  test('rejects unsupported and empty Lightning pay requests', () async {
    mintRepository.put(
      _mint(account, unsupportedMintUrl, supportsLightningPay: false),
    );

    await expectLater(
      controller.createQuote(
        mintUrl: unsupportedMintUrl,
        bolt11Invoice: 'lnbc420n1test',
      ),
      throwsA(isA<UnsupportedMintException>()),
    );
    await expectLater(
      controller.createQuote(mintUrl: unsupportedMintUrl, bolt11Invoice: ' '),
      throwsArgumentError,
    );
  });

  test('rejects quotes that exceed the selected Mint balance', () async {
    mintRepository.put(_mint(account, mintUrl));
    wallet.balances = {mintUrl: 43};

    await expectLater(
      controller.createQuote(mintUrl: mintUrl, bolt11Invoice: 'lnbc420n1test'),
      throwsA(
        isA<InsufficientCashuBalanceException>()
            .having((error) => error.availableSats, 'available', 43)
            .having((error) => error.requestedSats, 'requested', 44),
      ),
    );
  });
}

MintConfiguration _mint(
  CashuAccountId owner,
  CashuMintUrl url, {
  bool enabled = true,
  bool supportsLightningPay = true,
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
    if (supportsLightningPay) CashuNut.nut05,
    if (supportsLightningPay) CashuNut.nut08,
    if (supportsLightningPay) CashuNut.nut23,
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
  _Wallet(this.accountId, {required this.balances});

  @override
  final CashuAccountId accountId;
  Map<CashuMintUrl, int> balances;
  final List<String> createdInvoices = [];
  final List<String> paidQuoteIds = [];

  @override
  Future<Map<CashuMintUrl, int>> balancesByMintSats() async => balances;

  @override
  Future<CashuMeltQuote> createMeltQuote({
    required CashuMintUrl mintUrl,
    required String bolt11Invoice,
  }) async {
    createdInvoices.add(bolt11Invoice);
    return CashuMeltQuote(
      quoteId: 'melt-quote-1',
      mintUrl: mintUrl,
      amount: CashuAmount.sats(42),
      feeReserve: CashuAmount.sats(2),
      state: CashuQuoteState.unpaid,
      expiry: DateTime.utc(2026, 6, 29, 12),
    );
  }

  @override
  Future<CashuMeltResult> meltQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  }) async {
    paidQuoteIds.add(quoteId);
    return CashuMeltResult(
      quoteId: quoteId,
      state: CashuQuoteState.paid,
      amountSpent: CashuAmount.sats(43),
      feePaid: CashuAmount.sats(1),
      paymentPreimage: 'preimage',
    );
  }

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
  Future<CashuMintQuote> createMintQuote({
    required CashuMintUrl mintUrl,
    required CashuAmount amount,
  }) => throw UnimplementedError();

  @override
  Future<CashuMintQuote> checkMintQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  }) => throw UnimplementedError();

  @override
  Future<CashuAmount> mintQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  }) => throw UnimplementedError();

  @override
  Future<CashuReconciliationResult> reconcilePendingOperations() async =>
      const CashuReconciliationResult(
        recoveredOperations: 0,
        pendingOperations: 0,
      );

  @override
  Future<int> totalBalanceSats() async =>
      balances.values.fold<int>(0, (total, balance) => total + balance);

  @override
  Future<void> close() async {}
}
