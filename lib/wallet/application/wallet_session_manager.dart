import 'dart:async';
import 'dart:collection';

import '../domain/account_wallet.dart';
import '../domain/cashu_account_id.dart';
import '../domain/cashu_models.dart';

enum WalletSessionStatus { absent, ready }

final class WalletSessionState {
  const WalletSessionState._({
    required this.accountId,
    required this.status,
    required this.wallet,
  });

  const WalletSessionState.absent(CashuAccountId accountId)
    : this._(
        accountId: accountId,
        status: WalletSessionStatus.absent,
        wallet: null,
      );

  WalletSessionState.ready(AccountWalletSession wallet)
    : this._(
        accountId: wallet.accountId,
        status: WalletSessionStatus.ready,
        wallet: wallet,
      );

  final CashuAccountId accountId;
  final WalletSessionStatus status;
  final AccountWalletSession? wallet;
}

/// Owns the single active wallet session for the currently selected account.
///
/// Operations are serialized so rapid account changes cannot leave two CDK
/// repositories open or attach one account's session to another account.
final class WalletSessionManager {
  WalletSessionManager({required AccountWalletFactory factory})
    : _factory = factory;

  final AccountWalletFactory _factory;
  Future<void> _operationQueue = Future<void>.value();
  WalletSessionState? _activeState;
  bool _disposed = false;

  WalletSessionState? get activeState => _activeState;

  Future<WalletSessionState> activate(CashuAccountId accountId) {
    return _serialize(() async {
      _ensureNotDisposed();
      final current = _activeState;
      if (current?.accountId == accountId) return current!;

      await _closeActive();
      if (!await _factory.exists(accountId)) {
        return _activeState = WalletSessionState.absent(accountId);
      }

      final wallet = await _factory.openExisting(accountId);
      return _activeState = WalletSessionState.ready(wallet);
    });
  }

  Future<AccountWalletCreation<AccountWalletSession>> create(
    CashuAccountId accountId,
  ) {
    return _serialize(() async {
      _ensureNotDisposed();
      final current = _activeState;
      if (current?.accountId == accountId &&
          current?.status == WalletSessionStatus.ready) {
        throw StateError('Cashu wallet is already active for this account');
      }

      if (current?.accountId != accountId) await _closeActive();
      final creation = await _factory.createNew(accountId);
      _activeState = WalletSessionState.ready(creation.wallet);
      return creation;
    });
  }

  Future<void> closeActive() {
    return _serialize(() async {
      _ensureNotDisposed();
      await _closeActive();
    });
  }

  Future<void> dispose() {
    return _serialize(() async {
      if (_disposed) return;
      await _closeActive();
      _disposed = true;
    });
  }

  Future<void> _closeActive() async {
    final wallet = _activeState?.wallet;
    _activeState = null;
    await wallet?.close();
  }

  Future<T> _serialize<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _operationQueue = _operationQueue.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  void _ensureNotDisposed() {
    if (_disposed) throw StateError('WalletSessionManager is disposed');
  }
}

/// Coalesces concurrent lifecycle-triggered recovery requests.
final class PendingOperationRecoveryService {
  final Map<AccountWalletSession, Future<CashuReconciliationResult>> _inFlight =
      HashMap.identity();

  Future<CashuReconciliationResult> recover(AccountWalletSession wallet) {
    final running = _inFlight[wallet];
    if (running != null) return running;

    late final Future<CashuReconciliationResult> operation;
    operation = () async {
      try {
        return await wallet.reconcilePendingOperations();
      } finally {
        if (identical(_inFlight[wallet], operation)) {
          _inFlight.remove(wallet);
        }
      }
    }();
    _inFlight[wallet] = operation;
    return operation;
  }
}
