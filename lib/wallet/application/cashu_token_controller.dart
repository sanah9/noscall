import 'package:noscall/utils/hash_util.dart';

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

  Future<List<CashuTokenSendRecord>> loadSendRecords();

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
    required CashuTokenSendRepository sendRepository,
    required CashuTokenCodec tokenCodec,
    CashuTokenReceiveRepository? receiveRepository,
    DateTime Function()? clock,
  }) : _accountId = accountId,
       _sessionManager = sessionManager,
       _mintRepository = mintRepository,
       _sendRepository = sendRepository,
       _tokenCodec = tokenCodec,
       _receiveRepository = receiveRepository,
       _clock = clock ?? DateTime.now;

  final CashuAccountId _accountId;
  final WalletSessionManager _sessionManager;
  final MintConfigurationRepository _mintRepository;
  final CashuTokenSendRepository _sendRepository;
  final CashuTokenCodec _tokenCodec;
  final CashuTokenReceiveRepository? _receiveRepository;
  final DateTime Function() _clock;

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
  Future<List<CashuTokenSendRecord>> loadSendRecords() =>
      _sendRepository.list(_accountId);

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
    final receiptId = HashUtil.sha256String(summary.encodedToken);
    final existing = await _receiveRepository?.find(_accountId, receiptId);
    if (existing?.state == CashuReceiveState.received) {
      throw StateError('This token has already been received.');
    }
    final createdAt = existing?.createdAt ?? _clock();
    // Write a non-secret pending receipt before consuming the token.
    await _receiveRepository?.save(
      CashuTokenReceiveRecord(
        owner: _accountId,
        receiptId: receiptId,
        mintUrl: summary.mintUrl,
        amount: summary.amount,
        state: CashuReceiveState.pending,
        createdAt: createdAt,
      ),
    );
    final result = await wallet.receive(
      CashuReceiveRequest(encodedToken: summary.encodedToken),
    );
    try {
      await _receiveRepository?.save(
        CashuTokenReceiveRecord(
          owner: _accountId,
          receiptId: receiptId,
          mintUrl: summary.mintUrl,
          amount: result.amount,
          state: CashuReceiveState.received,
          createdAt: createdAt,
          operationId: result.operationId,
        ),
      );
      return result;
    } catch (_) {
      // Successful receipt must never be presented as a retryable payment failure.
      return CashuReceiveResult(
        operationId: result.operationId,
        amount: result.amount,
        historySaved: false,
      );
    }
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
    final prepared = await wallet.prepareSend(
      CashuSendRequest(mintUrl: mintUrl, amount: amount, memo: memo),
    );
    final now = _clock();
    await _sendRepository.save(
      CashuTokenSendRecord(
        owner: _accountId,
        operationId: prepared.operationId,
        mintUrl: mintUrl,
        amount: prepared.amount,
        state: CashuSendState.recoverable,
        createdAt: now,
        updatedAt: now,
        memo: _normalizedMemo(memo),
      ),
    );
    return prepared;
  }

  @override
  Future<CashuSendState> checkSendStatus({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) async {
    await _requireEnabledMint(mintUrl);
    final state = await (await _requireWallet()).checkSendStatus(
      mintUrl: mintUrl,
      operationId: operationId,
    );
    await _updateRecordState(operationId, state);
    return state;
  }

  @override
  Future<CashuAmount> reclaimSend({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) async {
    await _requireEnabledMint(mintUrl);
    final amount = await (await _requireWallet()).reclaimSend(
      mintUrl: mintUrl,
      operationId: operationId,
    );
    await _updateRecordState(operationId, CashuSendState.reclaimed);
    return amount;
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

  Future<void> _updateRecordState(
    String operationId,
    CashuSendState state,
  ) async {
    final record = await _sendRepository.find(_accountId, operationId);
    if (record == null) return;
    await _sendRepository.save(
      record.copyWith(state: state, updatedAt: _clock()),
    );
  }

  String? _normalizedMemo(String? memo) {
    final trimmed = memo?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
