import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/application/cashu_token_controller.dart';
import 'package:noscall/wallet/application/wallet_session_manager.dart';
import 'package:noscall/wallet/domain/account_wallet.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_engine.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';
import 'package:noscall/wallet/domain/wallet_configuration.dart';
import 'package:noscall/wallet/domain/wallet_errors.dart';

void main() {
  late CashuAccountId account;
  late CashuMintUrl mintUrl;
  late _TokenCodec codec;
  late _MintRepository mintRepository;
  late _SendRepository sendRepository;
  late _Wallet wallet;
  late AccountCashuTokenController controller;

  setUp(() {
    account = CashuAccountId.fromNostrPubkey('a' * 64);
    mintUrl = CashuMintUrl.parse('https://mint.example.com');
    codec = _TokenCodec(mintUrl);
    mintRepository = _MintRepository();
    sendRepository = _SendRepository();
    wallet = _Wallet(account, balances: {mintUrl: 100});
    controller = AccountCashuTokenController(
      accountId: account,
      sessionManager: WalletSessionManager(factory: _WalletFactory(wallet)),
      mintRepository: mintRepository,
      sendRepository: sendRepository,
      tokenCodec: codec,
      clock: () => DateTime.utc(2026, 6, 29, 12),
    );
  });

  test(
    'previews a token only when its Mint is configured and enabled',
    () async {
      await expectLater(
        controller.previewReceive('cashu-token'),
        throwsA(isA<UnknownMintException>()),
      );

      mintRepository.put(_mint(account, mintUrl, enabled: false));
      await expectLater(
        controller.previewReceive('cashu-token'),
        throwsA(isA<DisabledMintException>()),
      );

      mintRepository.put(_mint(account, mintUrl));
      final summary = await controller.previewReceive(' cashu-token ');

      expect(summary.encodedToken, 'cashu-token');
      expect(summary.mintUrl, mintUrl);
      expect(codec.decodeCalls, 3);
    },
  );

  test('receives through the active account wallet', () async {
    mintRepository.put(_mint(account, mintUrl));

    final result = await controller.receive(' cashu-token ');

    expect(result.amount, CashuAmount.sats(21));
    expect(wallet.receivedTokens, ['cashu-token']);
  });

  test('rejects sends that exceed the selected Mint balance', () async {
    mintRepository.put(_mint(account, mintUrl));

    await expectLater(
      controller.prepareSend(
        mintUrl: mintUrl,
        amount: CashuAmount.positiveSats(101),
      ),
      throwsA(
        isA<InsufficientCashuBalanceException>()
            .having((error) => error.availableSats, 'available', 100)
            .having((error) => error.requestedSats, 'requested', 101),
      ),
    );

    expect(wallet.sentRequests, isEmpty);
  });

  test('rejects zero-value sends before opening the wallet', () async {
    mintRepository.put(_mint(account, mintUrl));

    await expectLater(
      controller.prepareSend(mintUrl: mintUrl, amount: CashuAmount.sats(0)),
      throwsArgumentError,
    );

    expect(wallet.sentRequests, isEmpty);
  });

  test('prepares send and delegates status and reclaim operations', () async {
    mintRepository.put(_mint(account, mintUrl));

    final prepared = await controller.prepareSend(
      mintUrl: mintUrl,
      amount: CashuAmount.positiveSats(42),
      memo: ' lunch ',
    );
    final status = await controller.checkSendStatus(
      mintUrl: mintUrl,
      operationId: prepared.operationId,
    );
    final reclaimed = await controller.reclaimSend(
      mintUrl: mintUrl,
      operationId: prepared.operationId,
    );

    expect(prepared.operationId, 'send-1');
    expect(prepared.token, 'cashu-prepared-token');
    expect(wallet.sentRequests.single.memo, ' lunch ');
    expect(status, CashuSendState.recoverable);
    expect(reclaimed, CashuAmount.sats(42));
    expect(
      (await sendRepository.find(account, 'send-1'))?.state,
      CashuSendState.reclaimed,
    );
    expect((await sendRepository.find(account, 'send-1'))?.memo, 'lunch');
  });
}

MintConfiguration _mint(
  CashuAccountId owner,
  CashuMintUrl url, {
  bool enabled = true,
}) => MintConfiguration(
  owner: owner,
  url: url,
  enabled: enabled,
  source: MintConfigurationSource.manual,
  supportedNuts: const {
    CashuNut.nut00,
    CashuNut.nut01,
    CashuNut.nut02,
    CashuNut.nut03,
    CashuNut.nut06,
    CashuNut.nut07,
    CashuNut.nut09,
  },
  units: const ['sat'],
  lastSyncAt: DateTime.utc(2026, 6, 29),
);

final class _TokenCodec implements CashuTokenCodec {
  _TokenCodec(this.mintUrl);

  final CashuMintUrl mintUrl;
  int decodeCalls = 0;

  @override
  CashuTokenSummary decodeToken(String encodedToken) {
    decodeCalls++;
    return CashuTokenSummary(
      encodedToken: encodedToken.trim(),
      mintUrl: mintUrl,
      amount: CashuAmount.sats(21),
      version: 4,
      memo: null,
    );
  }
}

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

final class _SendRepository implements CashuTokenSendRepository {
  final Map<String, CashuTokenSendRecord> values = {};

  String _key(CashuAccountId owner, String operationId) =>
      '${owner.value}|$operationId';

  @override
  Future<CashuTokenSendRecord?> find(
    CashuAccountId owner,
    String operationId,
  ) async => values[_key(owner, operationId)];

  @override
  Future<List<CashuTokenSendRecord>> list(CashuAccountId owner) async => values
      .values
      .where((record) => record.owner == owner)
      .toList(growable: false);

  @override
  Future<void> save(CashuTokenSendRecord record) async {
    values[_key(record.owner, record.operationId)] = record;
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
  _Wallet(this.accountId, {required this.balances});

  @override
  final CashuAccountId accountId;
  final Map<CashuMintUrl, int> balances;
  final List<String> receivedTokens = [];
  final List<CashuSendRequest> sentRequests = [];

  @override
  Future<Map<CashuMintUrl, int>> balancesByMintSats() async => balances;

  @override
  Future<CashuReceiveResult> receive(CashuReceiveRequest request) async {
    receivedTokens.add(request.encodedToken);
    return CashuReceiveResult(
      operationId: 'receive-1',
      amount: CashuAmount.sats(21),
    );
  }

  @override
  Future<CashuPreparedSend> prepareSend(CashuSendRequest request) async {
    sentRequests.add(request);
    return CashuPreparedSend(
      operationId: 'send-1',
      token: 'cashu-prepared-token',
      amount: request.amount,
    );
  }

  @override
  Future<CashuSendState> checkSendStatus({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) async => CashuSendState.recoverable;

  @override
  Future<CashuAmount> reclaimSend({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) async => CashuAmount.sats(42);

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
  Future<CashuMeltQuote> createMeltQuote({
    required CashuMintUrl mintUrl,
    required String bolt11Invoice,
  }) => throw UnimplementedError();

  @override
  Future<CashuMeltResult> meltQuote({
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
