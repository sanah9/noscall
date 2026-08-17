import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_wallet_adapter.dart';
import 'package:noscall/wallet/domain/account_wallet.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  test('loads balances by Mint from account wallet session', () async {
    final mint = CashuMintUrl.parse('https://mint.example');
    final wallet = _Wallet(balances: {mint: 42});
    final adapter = AccountWalletCallPaymentAdapter(wallet);

    final balances = await adapter();

    expect(balances, {mint: 42});
  });

  test('adapts prepare send requests to wallet send requests', () async {
    final mint = CashuMintUrl.parse('https://mint.example');
    final wallet = _Wallet();
    final adapter = AccountWalletCallPaymentAdapter(wallet);

    final prepared = await adapter.prepareSend(
      mintUrl: mint,
      amount: CashuAmount.positiveSats(10),
      memo: 'paid call',
    );

    expect(prepared.token, 'cashuAey');
    expect(wallet.sendRequests.single.mintUrl, mint);
    expect(wallet.sendRequests.single.amount.value, 10);
    expect(wallet.sendRequests.single.memo, 'paid call');
  });

  test('adapts token receive requests to wallet receive requests', () async {
    final wallet = _Wallet();
    final adapter = AccountWalletCallPaymentAdapter(wallet);

    final result = await adapter.receive('cashuAey');

    expect(result.operationId, 'receive-op-1');
    expect(wallet.receiveRequests.single.encodedToken, 'cashuAey');
  });
}

final class _Wallet implements AccountWalletSession {
  _Wallet({Map<CashuMintUrl, int>? balances}) : _balances = balances ?? {};

  final Map<CashuMintUrl, int> _balances;
  final List<CashuSendRequest> sendRequests = [];
  final List<CashuReceiveRequest> receiveRequests = [];

  @override
  CashuAccountId get accountId => CashuAccountId.fromNostrPubkey('a' * 64);

  @override
  Future<Map<CashuMintUrl, int>> balancesByMintSats() async => _balances;

  @override
  Future<CashuPreparedSend> prepareSend(CashuSendRequest request) async {
    sendRequests.add(request);
    return CashuPreparedSend(
      operationId: 'send-op-1',
      token: 'cashuAey',
      amount: request.amount,
    );
  }

  @override
  Future<CashuReceiveResult> receive(CashuReceiveRequest request) async {
    receiveRequests.add(request);
    return CashuReceiveResult(
      operationId: 'receive-op-1',
      amount: CashuAmount.sats(10),
    );
  }

  @override
  Future<CashuSendState> checkSendStatus({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> close() async {}

  @override
  Future<CashuMintQuote> checkMintQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CashuMintQuote> createMintQuote({
    required CashuMintUrl mintUrl,
    required CashuAmount amount,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CashuMeltQuote> createMeltQuote({
    required CashuMintUrl mintUrl,
    required String bolt11Invoice,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CashuMeltResult> meltQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CashuAmount> mintQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CashuAmount> reclaimSend({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CashuReconciliationResult> reconcilePendingOperations() {
    throw UnimplementedError();
  }

  @override
  Future<int> totalBalanceSats() {
    throw UnimplementedError();
  }
}
