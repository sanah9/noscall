import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';
import 'package:noscall/wallet/domain/wallet_configuration.dart';
import 'package:noscall/wallet/infrastructure/database/isar_wallet_configuration_repository.dart';
import 'package:noscall/wallet/infrastructure/database/wallet_configuration_isar.dart';

void main() {
  late Directory directory;
  Isar? isar;
  late IsarWalletConfigurationRepository walletRepository;
  late IsarMintConfigurationRepository mintRepository;
  late IsarCashuTokenSendRepository sendRepository;

  setUpAll(_initializeIsarForTests);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('noscall_wallet_isar_');
    final database = isar = await Isar.open(
      [
        CashuWalletConfigurationRecordSchema,
        CashuMintConfigurationRecordSchema,
        CashuTokenSendOperationRecordSchema,
      ],
      directory: directory.path,
      name: 'wallet_configuration_test',
    );
    walletRepository = IsarWalletConfigurationRepository(database);
    mintRepository = IsarMintConfigurationRepository(database);
    sendRepository = IsarCashuTokenSendRepository(database);
  });

  tearDown(() async {
    final database = isar;
    if (database != null && database.isOpen) {
      await database.close(deleteFromDisk: true);
    }
    isar = null;
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('upserts one wallet configuration per Nostr account', () async {
    final owner = _account('a');
    final createdAt = DateTime.utc(2026, 6, 20);
    final configuration = WalletConfiguration(
      owner: owner,
      seedReference: owner.seedReference,
      backupStatus: WalletBackupStatus.notShown,
      createdAt: createdAt,
      updatedAt: createdAt,
      schemaVersion: 1,
    );

    await walletRepository.save(configuration);
    await walletRepository.save(
      configuration.copyWith(
        backupStatus: WalletBackupStatus.confirmed,
        updatedAt: createdAt.add(const Duration(minutes: 1)),
      ),
    );

    final stored = await walletRepository.find(owner);
    expect(stored?.backupStatus, WalletBackupStatus.confirmed);
    expect(await isar!.cashuWalletConfigurationRecords.count(), 1);
  });

  test('isolates equal Mint URLs between Nostr accounts', () async {
    final ownerA = _account('a');
    final ownerB = _account('b');
    final url = CashuMintUrl.parse('https://mint.example.com/');
    final now = DateTime.utc(2026, 6, 20);

    await mintRepository.save(
      _mint(owner: ownerA, url: url, enabled: true, now: now),
    );
    await mintRepository.save(
      _mint(owner: ownerB, url: url, enabled: false, now: now),
    );

    expect((await mintRepository.list(ownerA)).single.enabled, isTrue);
    expect((await mintRepository.list(ownerB)).single.enabled, isFalse);

    await mintRepository.delete(ownerA, url);
    expect(await mintRepository.list(ownerA), isEmpty);
    expect(await mintRepository.list(ownerB), hasLength(1));
  });

  test('upserts and isolates token send records by Nostr account', () async {
    final ownerA = _account('a');
    final ownerB = _account('b');
    final url = CashuMintUrl.parse('https://mint.example.com');
    final now = DateTime.utc(2026, 6, 29);

    await sendRepository.save(
      _send(
        owner: ownerA,
        url: url,
        operationId: 'send-1',
        state: CashuSendState.recoverable,
        now: now,
      ),
    );
    await sendRepository.save(
      _send(
        owner: ownerB,
        url: url,
        operationId: 'send-1',
        state: CashuSendState.claimed,
        now: now,
      ),
    );
    await sendRepository.save(
      _send(
        owner: ownerA,
        url: url,
        operationId: 'send-1',
        state: CashuSendState.reclaimed,
        now: now.add(const Duration(minutes: 1)),
      ),
    );

    expect(
      (await sendRepository.find(ownerA, 'send-1'))?.state,
      CashuSendState.reclaimed,
    );
    expect(
      (await sendRepository.find(ownerB, 'send-1'))?.state,
      CashuSendState.claimed,
    );
    expect(await sendRepository.list(ownerA), hasLength(1));
  });
}

Future<void> _initializeIsarForTests() async {
  final pubCache =
      Platform.environment['PUB_CACHE'] ??
      '${Platform.environment['HOME']}/.pub-cache';
  final packageRoot =
      '$pubCache/hosted/pub.dev/isar_flutter_libs-${Isar.version}';
  late final String libraryPath;
  if (Platform.isMacOS) {
    libraryPath = '$packageRoot/macos/libisar.dylib';
  } else if (Platform.isLinux) {
    libraryPath = '$packageRoot/linux/libisar.so';
  } else if (Platform.isWindows) {
    libraryPath = '$packageRoot/windows/isar.dll';
  } else {
    throw UnsupportedError('Isar VM tests are unsupported on this platform');
  }
  await Isar.initializeIsarCore(libraries: {Abi.current(): libraryPath});
}

CashuAccountId _account(String character) =>
    CashuAccountId.fromNostrPubkey(character * 64);

MintConfiguration _mint({
  required CashuAccountId owner,
  required CashuMintUrl url,
  required bool enabled,
  required DateTime now,
}) {
  return MintConfiguration(
    owner: owner,
    url: url,
    name: 'Test Mint',
    enabled: enabled,
    source: MintConfigurationSource.manual,
    supportedNuts: {CashuNut.nut00, CashuNut.nut01},
    units: const ['sat'],
    lastSyncAt: now,
  );
}

CashuTokenSendRecord _send({
  required CashuAccountId owner,
  required CashuMintUrl url,
  required String operationId,
  required CashuSendState state,
  required DateTime now,
}) {
  return CashuTokenSendRecord(
    owner: owner,
    operationId: operationId,
    mintUrl: url,
    amount: CashuAmount.sats(42),
    state: state,
    createdAt: now,
    updatedAt: now,
    memo: 'memo',
  );
}
