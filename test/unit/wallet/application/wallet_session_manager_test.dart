import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/application/wallet_session_manager.dart';
import 'package:noscall/wallet/domain/account_wallet.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  late _FakeAccountWalletFactory factory;
  late WalletSessionManager manager;

  setUp(() {
    factory = _FakeAccountWalletFactory();
    manager = WalletSessionManager(factory: factory);
  });

  tearDown(() => manager.dispose());

  test('activating an account without a wallet never creates one', () async {
    final account = _account('a');

    final state = await manager.activate(account);

    expect(state.status, WalletSessionStatus.absent);
    expect(state.wallet, isNull);
    expect(factory.createCalls, 0);
    expect(factory.openCalls, 0);
  });

  test('switching accounts closes the previous wallet first', () async {
    final accountA = _account('a');
    final accountB = _account('b');
    final walletA = factory.addExisting(accountA);
    final walletB = factory.addExisting(accountB);

    await manager.activate(accountA);
    final stateB = await manager.activate(accountB);

    expect(walletA.closeCalls, 1);
    expect(walletB.closeCalls, 0);
    expect(stateB.accountId, accountB);
    expect(stateB.wallet, same(walletB));
    expect(walletA.recoveryCalls, 1);
    expect(walletB.recoveryCalls, 1);
  });

  test('does not expose a wallet when startup recovery fails', () async {
    final account = _account('e');
    final wallet = factory.addExisting(account);
    wallet.recoveryError = StateError('recovery failed');

    final activation = manager.activate(account);

    await expectLater(activation, throwsStateError);
    expect(wallet.closeCalls, 1);
    expect(manager.activeState, isNull);
  });

  test('rapid account changes remain serialized and isolated', () async {
    final accountA = _account('a');
    final accountB = _account('b');
    final walletA = factory.addExisting(accountA);
    final walletB = factory.addExisting(accountB);

    final activations = await Future.wait([
      manager.activate(accountA),
      manager.activate(accountB),
    ]);

    expect(activations.first.wallet, same(walletA));
    expect(activations.last.wallet, same(walletB));
    expect(walletA.closeCalls, 1);
    expect(manager.activeState?.wallet, same(walletB));
  });

  test(
    'create explicitly creates and activates only the requested account',
    () async {
      final account = _account('c');

      final creation = await manager.create(account);

      expect(factory.createCalls, 1);
      expect(creation.wallet.accountId, account);
      expect(manager.activeState?.status, WalletSessionStatus.ready);
      expect(() => manager.create(account), throwsStateError);
    },
  );

  test('pending recovery coalesces concurrent lifecycle triggers', () async {
    final wallet = _FakeAccountWallet(_account('d'));
    final recovery = PendingOperationRecoveryService();
    final result = Completer<CashuReconciliationResult>();
    wallet.recoveryResult = result;

    final first = recovery.recover(wallet);
    final second = recovery.recover(wallet);
    result.complete(
      const CashuReconciliationResult(
        recoveredOperations: 2,
        pendingOperations: 1,
      ),
    );

    expect(await first, same(await second));
    expect(wallet.recoveryCalls, 1);
  });

  test(
    'pending recovery never shares results between account sessions',
    () async {
      final walletA = _FakeAccountWallet(_account('a'));
      final walletB = _FakeAccountWallet(_account('b'));
      final recovery = PendingOperationRecoveryService();

      final results = await Future.wait([
        recovery.recover(walletA),
        recovery.recover(walletB),
      ]);

      expect(results, hasLength(2));
      expect(walletA.recoveryCalls, 1);
      expect(walletB.recoveryCalls, 1);
    },
  );
}

CashuAccountId _account(String character) =>
    CashuAccountId.fromNostrPubkey(character * 64);

final class _FakeAccountWalletFactory implements AccountWalletFactory {
  final Map<CashuAccountId, _FakeAccountWallet> wallets = {};
  int createCalls = 0;
  int openCalls = 0;

  _FakeAccountWallet addExisting(CashuAccountId accountId) {
    return wallets[accountId] = _FakeAccountWallet(accountId);
  }

  @override
  Future<bool> exists(CashuAccountId accountId) async =>
      wallets.containsKey(accountId);

  @override
  Future<AccountWalletCreation<_FakeAccountWallet>> createNew(
    CashuAccountId accountId,
  ) async {
    createCalls++;
    if (wallets.containsKey(accountId)) throw StateError('already exists');
    final wallet = addExisting(accountId);
    return AccountWalletCreation(wallet: wallet, mnemonic: 'test mnemonic');
  }

  @override
  Future<_FakeAccountWallet> openExisting(CashuAccountId accountId) async {
    openCalls++;
    final wallet = wallets[accountId];
    if (wallet == null) throw StateError('missing');
    return wallet;
  }
}

final class _FakeAccountWallet implements AccountWalletSession {
  _FakeAccountWallet(this.accountId);

  @override
  final CashuAccountId accountId;
  int closeCalls = 0;
  int recoveryCalls = 0;
  Completer<CashuReconciliationResult>? recoveryResult;
  Object? recoveryError;

  @override
  Future<void> close() async => closeCalls++;

  @override
  Future<CashuReconciliationResult> reconcilePendingOperations() async {
    recoveryCalls++;
    final error = recoveryError;
    if (error != null) throw error;
    return await recoveryResult?.future ??
        const CashuReconciliationResult(
          recoveredOperations: 0,
          pendingOperations: 0,
        );
  }

  @override
  Future<int> totalBalanceSats() async => 0;

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
}
