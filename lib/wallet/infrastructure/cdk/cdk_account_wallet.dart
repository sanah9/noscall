import 'dart:io';

import 'package:cdk/cdk.dart' as cdk;

import '../../domain/cashu_account_id.dart';
import '../../domain/cashu_models.dart';
import '../../domain/wallet_key_store.dart';

final class CdkAccountWalletFactory {
  CdkAccountWalletFactory({
    required this.walletsRoot,
    required this.keyStore,
    this.allowInsecureDevelopmentStore = false,
  });

  final Directory walletsRoot;
  final WalletKeyStore keyStore;
  final bool allowInsecureDevelopmentStore;

  Future<CdkWalletCreation> createNew(CashuAccountId accountId) async {
    _validateKeyStore();
    final reference = accountId.seedReference;
    if (await keyStore.readMnemonic(reference) != null) {
      throw StateError('Cashu wallet already exists for this account');
    }

    final mnemonic = cdk.generateMnemonic();
    _validateTwelveWordMnemonic(mnemonic);

    // Persist before opening SQLite. If process startup fails after this point,
    // the same seed remains available and openExisting can safely retry.
    await keyStore.writeMnemonic(reference, mnemonic);
    final wallet = await _open(accountId, mnemonic);
    return CdkWalletCreation(wallet: wallet, mnemonic: mnemonic);
  }

  Future<CdkAccountWallet> openExisting(CashuAccountId accountId) async {
    _validateKeyStore();
    final mnemonic = await keyStore.readMnemonic(accountId.seedReference);
    if (mnemonic == null) {
      throw StateError('Cashu wallet does not exist for this account');
    }
    _validateTwelveWordMnemonic(mnemonic);
    return _open(accountId, mnemonic);
  }

  Future<CdkAccountWallet> _open(
    CashuAccountId accountId,
    String mnemonic,
  ) async {
    final accountDirectory = Directory(
      '${walletsRoot.path}/${accountId.value}',
    );
    await accountDirectory.create(recursive: true);
    final databaseFile = File('${accountDirectory.path}/cdk.sqlite3');
    final repository = cdk.WalletRepository(
      mnemonic: mnemonic,
      store: cdk.SqliteWalletStore(databaseFile.path),
    );
    return CdkAccountWallet._(
      accountId: accountId,
      databaseFile: databaseFile,
      repository: repository,
    );
  }

  void _validateKeyStore() {
    if (!keyStore.isProductionReady && !allowInsecureDevelopmentStore) {
      throw StateError(
        'Development WalletKeyStore requires explicit insecure opt-in',
      );
    }
  }

  void _validateTwelveWordMnemonic(String mnemonic) {
    final words = mnemonic.trim().split(RegExp(r'\s+'));
    if (words.length != 12 ||
        cdk.mnemonicToEntropy(mnemonic: mnemonic).length != 16) {
      throw const FormatException('Cashu wallet requires a 12-word mnemonic');
    }
  }
}

final class CdkWalletCreation {
  const CdkWalletCreation({required this.wallet, required this.mnemonic});

  final CdkAccountWallet wallet;

  /// Returned once so the future backup UI can display it to the user.
  /// This value must never be logged or persisted outside WalletKeyStore.
  final String mnemonic;
}

final class CdkAccountWallet {
  CdkAccountWallet._({
    required this.accountId,
    required this.databaseFile,
    required cdk.WalletRepository repository,
  }) : _repository = repository;

  final CashuAccountId accountId;
  final File databaseFile;
  final cdk.WalletRepository _repository;
  final Map<CashuMintUrl, cdk.Wallet> _wallets = {};
  bool _closed = false;

  Future<bool> hasMint(CashuMintUrl mintUrl) {
    _ensureOpen();
    return _repository.hasMint(mintUrl: cdk.MintUrl(url: mintUrl.toString()));
  }

  /// Adds a sat-denominated Mint only when explicitly requested by the user.
  /// No default Mint is created when the account wallet opens.
  Future<cdk.Wallet> addOrOpenMint(CashuMintUrl mintUrl) async {
    _ensureOpen();
    final cached = _wallets[mintUrl];
    if (cached != null) return cached;

    final cdkUrl = cdk.MintUrl(url: mintUrl.toString());
    if (!await _repository.hasMint(mintUrl: cdkUrl)) {
      await _repository.createWallet(
        mintUrl: cdkUrl,
        unit: cdk.SatCurrencyUnit(),
        targetProofCount: null,
      );
    }
    final wallet = await _repository.getWallet(
      mintUrl: cdkUrl,
      unit: cdk.SatCurrencyUnit(),
    );
    _wallets[mintUrl] = wallet;
    return wallet;
  }

  Future<int> totalBalanceSats() async {
    _ensureOpen();
    final balances = await _repository.getBalances();
    return balances.values.fold<int>(
      0,
      (total, amount) => total + amount.value,
    );
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    for (final wallet in _wallets.values) {
      wallet.dispose();
    }
    _wallets.clear();
    _repository.dispose();
  }

  void _ensureOpen() {
    if (_closed) throw StateError('Cashu wallet session is closed');
  }
}
