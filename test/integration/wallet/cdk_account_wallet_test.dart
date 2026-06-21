import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';
import 'package:noscall/wallet/infrastructure/cdk/cdk_account_wallet.dart';
import 'package:noscall/wallet/infrastructure/security/development_file_wallet_key_store.dart';

void main() {
  late Directory temporaryDirectory;
  late DevelopmentFileWalletKeyStore keyStore;
  late CdkAccountWalletFactory factory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'noscall_cdk_account_wallet_',
    );
    keyStore = DevelopmentFileWalletKeyStore(
      Directory('${temporaryDirectory.path}/development-seeds'),
    );
    factory = CdkAccountWalletFactory(
      walletsRoot: Directory('${temporaryDirectory.path}/wallets'),
      keyStore: keyStore,
      allowInsecureDevelopmentStore: true,
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('keeps Nostr account seeds and SQLite databases isolated', () async {
    final accountA = CashuAccountId.fromNostrPubkey('a' * 64);
    final accountB = CashuAccountId.fromNostrPubkey('b' * 64);

    final createdA = await factory.createNew(accountA);
    final createdB = await factory.createNew(accountB);
    addTearDown(createdA.wallet.close);
    addTearDown(createdB.wallet.close);

    expect(createdA.mnemonic, isNot(equals(createdB.mnemonic)));
    expect(
      createdA.wallet.databaseFile.path,
      isNot(createdB.wallet.databaseFile.path),
    );
    expect(await createdA.wallet.databaseFile.exists(), isTrue);
    expect(await createdB.wallet.databaseFile.exists(), isTrue);
    expect(await createdA.wallet.totalBalanceSats(), 0);
    expect(await createdB.wallet.totalBalanceSats(), 0);
    expect(await createdA.wallet.balancesByMintSats(), isEmpty);
    expect(
      await createdA.wallet.hasMint(
        CashuMintUrl.parse('https://mint.example.com'),
      ),
      isFalse,
    );
  });

  test('reopens the same account and SQLite store after restart', () async {
    final account = CashuAccountId.fromNostrPubkey('c' * 64);
    final created = await factory.createNew(account);
    final databasePath = created.wallet.databaseFile.path;
    final mnemonic = created.mnemonic;
    await created.wallet.close();

    final reopened = await factory.openExisting(account);
    addTearDown(reopened.close);

    expect(reopened.databaseFile.path, databasePath);
    expect(await keyStore.readMnemonic(account.seedReference), mnemonic);
    expect(await reopened.totalBalanceSats(), 0);
  });

  test(
    'reconciles an empty account wallet without inventing operations',
    () async {
      final account = CashuAccountId.fromNostrPubkey('f' * 64);
      final created = await factory.createNew(account);
      addTearDown(created.wallet.close);

      final result = await created.wallet.reconcilePendingOperations();

      expect(result.recoveredOperations, 0);
      expect(result.pendingOperations, 0);
    },
  );

  test('requires explicit opt-in for the development seed store', () async {
    final guardedFactory = CdkAccountWalletFactory(
      walletsRoot: Directory('${temporaryDirectory.path}/guarded-wallets'),
      keyStore: keyStore,
    );
    final account = CashuAccountId.fromNostrPubkey('d' * 64);

    expect(guardedFactory.createNew(account), throwsStateError);
  });

  test('does not silently replace an existing account seed', () async {
    final account = CashuAccountId.fromNostrPubkey('e' * 64);
    final created = await factory.createNew(account);
    addTearDown(created.wallet.close);

    expect(factory.createNew(account), throwsStateError);
  });
}
