import '../domain/account_wallet.dart';
import '../domain/cashu_account_id.dart';
import '../domain/cashu_engine.dart';
import '../domain/cashu_models.dart';
import '../domain/wallet_configuration.dart';
import '../domain/wallet_errors.dart';
import 'wallet_session_manager.dart';

final class CashuTokenMintOption {
  const CashuTokenMintOption({required this.mint, required this.balanceSats});

  final MintConfiguration mint;
  final int balanceSats;
}

abstract interface class CashuTokenController {
  Future<List<CashuTokenMintOption>> loadSendOptions();

  Future<CashuTokenSummary> previewReceive(String encodedToken);

  Future<CashuReceiveResult> receive(String encodedToken);

  Future<CashuPreparedSend> prepareSend({
    required CashuMintUrl mintUrl,
    required CashuAmount amount,
    String? memo,
  });

  Future<CashuSendState> checkSendStatus({
    required CashuMintUrl mintUrl,
    required String operationId,
  });

  Future<CashuAmount> reclaimSend({
    required CashuMintUrl mintUrl,
    required String operationId,
  });
}

final class AccountCashuTokenController implements CashuTokenController {
  AccountCashuTokenController({
    required CashuAccountId accountId,
    required WalletSessionManager sessionManager,
    required MintConfigurationRepository mintRepository,
    required CashuTokenCodec tokenCodec,
  }) : _accountId = accountId,
       _sessionManager = sessionManager,
       _mintRepository = mintRepository,
       _tokenCodec = tokenCodec;

  final CashuAccountId _accountId;
  final WalletSessionManager _sessionManager;
  final MintConfigurationRepository _mintRepository;
  final CashuTokenCodec _tokenCodec;

  @override
  Future<List<CashuTokenMintOption>> loadSendOptions() async {
    final wallet = await _requireWallet();
    final balances = await wallet.balancesByMintSats();
    final mints = await _mintRepository.list(_accountId);
    return List.unmodifiable(
      mints
          .where((mint) => mint.enabled)
          .map(
            (mint) => CashuTokenMintOption(
              mint: mint,
              balanceSats: balances[mint.url] ?? 0,
            ),
          ),
    );
  }

  @override
  Future<CashuTokenSummary> previewReceive(String encodedToken) async {
    final summary = _tokenCodec.decodeToken(encodedToken);
    await _requireEnabledMint(summary.mintUrl);
    return summary;
  }

  @override
  Future<CashuReceiveResult> receive(String encodedToken) async {
    final summary = await previewReceive(encodedToken);
    final wallet = await _requireWallet();
    return wallet.receive(
      CashuReceiveRequest(encodedToken: summary.encodedToken),
    );
  }

  @override
  Future<CashuPreparedSend> prepareSend({
    required CashuMintUrl mintUrl,
    required CashuAmount amount,
    String? memo,
  }) async {
    if (amount.value <= 0) {
      throw ArgumentError.value(
        amount.value,
        'amount',
        'Send amount must be positive',
      );
    }
    await _requireEnabledMint(mintUrl);
    final wallet = await _requireWallet();
    final balance = (await wallet.balancesByMintSats())[mintUrl] ?? 0;
    if (balance < amount.value) {
      throw InsufficientCashuBalanceException(
        availableSats: balance,
        requestedSats: amount.value,
      );
    }
    return wallet.prepareSend(
      CashuSendRequest(mintUrl: mintUrl, amount: amount, memo: memo),
    );
  }

  @override
  Future<CashuSendState> checkSendStatus({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) async {
    await _requireEnabledMint(mintUrl);
    return (await _requireWallet()).checkSendStatus(
      mintUrl: mintUrl,
      operationId: operationId,
    );
  }

  @override
  Future<CashuAmount> reclaimSend({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) async {
    await _requireEnabledMint(mintUrl);
    return (await _requireWallet()).reclaimSend(
      mintUrl: mintUrl,
      operationId: operationId,
    );
  }

  Future<AccountWalletSession> _requireWallet() async {
    final session = await _sessionManager.activate(_accountId);
    final wallet = session.wallet;
    if (wallet == null) throw const WalletNotReadyException();
    return wallet;
  }

  Future<void> _requireEnabledMint(CashuMintUrl mintUrl) async {
    final configuration = await _mintRepository.find(_accountId, mintUrl);
    if (configuration == null) throw UnknownMintException(mintUrl);
    if (!configuration.enabled) throw DisabledMintException(mintUrl);
  }
}
