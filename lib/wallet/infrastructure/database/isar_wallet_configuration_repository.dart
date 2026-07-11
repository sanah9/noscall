import 'package:isar/isar.dart';

import '../../domain/cashu_account_id.dart';
import '../../domain/cashu_models.dart';
import '../../domain/wallet_configuration.dart';
import 'wallet_configuration_isar.dart';

final class IsarWalletConfigurationRepository
    implements WalletConfigurationRepository {
  const IsarWalletConfigurationRepository(this._isar);

  final Isar _isar;

  @override
  Future<WalletConfiguration?> find(CashuAccountId owner) async {
    final record = await _isar.cashuWalletConfigurationRecords
        .where()
        .ownerPubkeyEqualTo(owner.value)
        .findFirst();
    return record == null ? null : _walletFromRecord(record);
  }

  @override
  Future<void> save(WalletConfiguration configuration) async {
    final record = _walletToRecord(configuration);
    await _isar.writeTxn(
      () => _isar.cashuWalletConfigurationRecords.put(record),
    );
  }
}

final class IsarMintConfigurationRepository
    implements MintConfigurationRepository {
  const IsarMintConfigurationRepository(this._isar);

  final Isar _isar;

  @override
  Future<MintConfiguration?> find(
    CashuAccountId owner,
    CashuMintUrl url,
  ) async {
    final record = await _isar.cashuMintConfigurationRecords
        .where()
        .ownerPubkeyNormalizedUrlEqualTo(owner.value, url.toString())
        .findFirst();
    return record == null ? null : _mintFromRecord(record);
  }

  @override
  Future<List<MintConfiguration>> list(CashuAccountId owner) async {
    final records = await _isar.cashuMintConfigurationRecords
        .filter()
        .ownerPubkeyEqualTo(owner.value)
        .findAll();
    records.sort((a, b) => a.normalizedUrl.compareTo(b.normalizedUrl));
    return List.unmodifiable(records.map(_mintFromRecord));
  }

  @override
  Future<void> save(MintConfiguration configuration) async {
    final record = _mintToRecord(configuration);
    await _isar.writeTxn(() => _isar.cashuMintConfigurationRecords.put(record));
  }

  @override
  Future<void> delete(CashuAccountId owner, CashuMintUrl url) async {
    await _isar.writeTxn(
      () => _isar.cashuMintConfigurationRecords
          .where()
          .ownerPubkeyNormalizedUrlEqualTo(owner.value, url.toString())
          .deleteAll(),
    );
  }
}

final class IsarCashuTokenSendRepository implements CashuTokenSendRepository {
  const IsarCashuTokenSendRepository(this._isar);

  final Isar _isar;

  @override
  Future<CashuTokenSendRecord?> find(
    CashuAccountId owner,
    String operationId,
  ) async {
    final record = await _isar.cashuTokenSendOperationRecords
        .where()
        .ownerPubkeyOperationIdEqualTo(owner.value, operationId)
        .findFirst();
    return record == null ? null : _sendFromRecord(record);
  }

  @override
  Future<List<CashuTokenSendRecord>> list(CashuAccountId owner) async {
    final records = await _isar.cashuTokenSendOperationRecords
        .filter()
        .ownerPubkeyEqualTo(owner.value)
        .findAll();
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(records.map(_sendFromRecord));
  }

  @override
  Future<void> save(CashuTokenSendRecord record) async {
    await _isar.writeTxn(
      () => _isar.cashuTokenSendOperationRecords.put(_sendToRecord(record)),
    );
  }
}

final class IsarCashuLightningReceiveQuoteRepository
    implements CashuLightningReceiveQuoteRepository {
  const IsarCashuLightningReceiveQuoteRepository(this._isar);

  final Isar _isar;

  @override
  Future<CashuLightningReceiveQuoteRecord?> find(
    CashuAccountId owner,
    String quoteId,
  ) async {
    final record = await _isar.cashuLightningReceiveQuoteOperationRecords
        .where()
        .ownerPubkeyQuoteIdEqualTo(owner.value, quoteId)
        .findFirst();
    return record == null ? null : _receiveQuoteFromRecord(record);
  }

  @override
  Future<List<CashuLightningReceiveQuoteRecord>> list(
    CashuAccountId owner,
  ) async {
    final records = await _isar.cashuLightningReceiveQuoteOperationRecords
        .filter()
        .ownerPubkeyEqualTo(owner.value)
        .findAll();
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(records.map(_receiveQuoteFromRecord));
  }

  @override
  Future<void> save(CashuLightningReceiveQuoteRecord record) async {
    await _isar.writeTxn(
      () => _isar.cashuLightningReceiveQuoteOperationRecords.put(
        _receiveQuoteToRecord(record),
      ),
    );
  }
}

final class IsarCashuLightningPayQuoteRepository
    implements CashuLightningPayQuoteRepository {
  const IsarCashuLightningPayQuoteRepository(this._isar);

  final Isar _isar;

  @override
  Future<CashuLightningPayQuoteRecord?> find(
    CashuAccountId owner,
    String quoteId,
  ) async {
    final record = await _isar.cashuLightningPayQuoteOperationRecords
        .where()
        .ownerPubkeyQuoteIdEqualTo(owner.value, quoteId)
        .findFirst();
    return record == null ? null : _payQuoteFromRecord(record);
  }

  @override
  Future<List<CashuLightningPayQuoteRecord>> list(CashuAccountId owner) async {
    final records = await _isar.cashuLightningPayQuoteOperationRecords
        .filter()
        .ownerPubkeyEqualTo(owner.value)
        .findAll();
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(records.map(_payQuoteFromRecord));
  }

  @override
  Future<void> save(CashuLightningPayQuoteRecord record) async {
    await _isar.writeTxn(
      () => _isar.cashuLightningPayQuoteOperationRecords.put(
        _payQuoteToRecord(record),
      ),
    );
  }
}

CashuWalletConfigurationRecord _walletToRecord(
  WalletConfiguration configuration,
) {
  return CashuWalletConfigurationRecord()
    ..ownerPubkey = configuration.owner.value
    ..seedReference = configuration.seedReference
    ..backupStatus = configuration.backupStatus.name
    ..createdAt = configuration.createdAt.millisecondsSinceEpoch
    ..updatedAt = configuration.updatedAt.millisecondsSinceEpoch
    ..schemaVersion = configuration.schemaVersion;
}

WalletConfiguration _walletFromRecord(CashuWalletConfigurationRecord record) {
  return WalletConfiguration(
    owner: CashuAccountId.fromNostrPubkey(record.ownerPubkey),
    seedReference: record.seedReference,
    backupStatus: WalletBackupStatus.values.byName(record.backupStatus),
    createdAt: DateTime.fromMillisecondsSinceEpoch(record.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(record.updatedAt),
    schemaVersion: record.schemaVersion,
  );
}

CashuMintConfigurationRecord _mintToRecord(MintConfiguration configuration) {
  return CashuMintConfigurationRecord()
    ..ownerPubkey = configuration.owner.value
    ..normalizedUrl = configuration.url.toString()
    ..name = configuration.name
    ..description = configuration.description
    ..enabled = configuration.enabled
    ..source = configuration.source.name
    ..supportedNutNumbers = configuration.supportedNuts
        .map((nut) => nut.number)
        .toList(growable: false)
    ..units = configuration.units.toList(growable: false)
    ..lastSyncAt = configuration.lastSyncAt.millisecondsSinceEpoch
    ..lastError = configuration.lastError;
}

final Map<int, CashuNut> _nutsByNumber = {
  for (final nut in CashuNut.values) nut.number: nut,
};

MintConfiguration _mintFromRecord(CashuMintConfigurationRecord record) {
  return MintConfiguration(
    owner: CashuAccountId.fromNostrPubkey(record.ownerPubkey),
    url: CashuMintUrl.parse(record.normalizedUrl),
    name: record.name,
    description: record.description,
    enabled: record.enabled,
    source: MintConfigurationSource.values.byName(record.source),
    supportedNuts: record.supportedNutNumbers
        .map((number) => _nutsByNumber[number])
        .whereType<CashuNut>()
        .toSet(),
    units: record.units,
    lastSyncAt: DateTime.fromMillisecondsSinceEpoch(record.lastSyncAt),
    lastError: record.lastError,
  );
}

CashuTokenSendOperationRecord _sendToRecord(CashuTokenSendRecord record) {
  return CashuTokenSendOperationRecord()
    ..ownerPubkey = record.owner.value
    ..operationId = record.operationId
    ..mintUrl = record.mintUrl.toString()
    ..amountSats = record.amount.value
    ..state = record.state.name
    ..memo = record.memo
    ..createdAt = record.createdAt.millisecondsSinceEpoch
    ..updatedAt = record.updatedAt.millisecondsSinceEpoch;
}

CashuTokenSendRecord _sendFromRecord(CashuTokenSendOperationRecord record) {
  return CashuTokenSendRecord(
    owner: CashuAccountId.fromNostrPubkey(record.ownerPubkey),
    operationId: record.operationId,
    mintUrl: CashuMintUrl.parse(record.mintUrl),
    amount: CashuAmount.sats(record.amountSats),
    state: CashuSendState.values.byName(record.state),
    memo: record.memo,
    createdAt: DateTime.fromMillisecondsSinceEpoch(record.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(record.updatedAt),
  );
}

CashuLightningReceiveQuoteOperationRecord _receiveQuoteToRecord(
  CashuLightningReceiveQuoteRecord record,
) {
  return CashuLightningReceiveQuoteOperationRecord()
    ..ownerPubkey = record.owner.value
    ..quoteId = record.quoteId
    ..mintUrl = record.mintUrl.toString()
    ..amountSats = record.amount.value
    ..request = record.request
    ..state = record.state.name
    ..expiry = record.expiry.millisecondsSinceEpoch
    ..createdAt = record.createdAt.millisecondsSinceEpoch
    ..updatedAt = record.updatedAt.millisecondsSinceEpoch;
}

CashuLightningReceiveQuoteRecord _receiveQuoteFromRecord(
  CashuLightningReceiveQuoteOperationRecord record,
) {
  return CashuLightningReceiveQuoteRecord(
    owner: CashuAccountId.fromNostrPubkey(record.ownerPubkey),
    quoteId: record.quoteId,
    mintUrl: CashuMintUrl.parse(record.mintUrl),
    amount: CashuAmount.sats(record.amountSats),
    request: record.request,
    state: CashuQuoteState.values.byName(record.state),
    expiry: DateTime.fromMillisecondsSinceEpoch(record.expiry),
    createdAt: DateTime.fromMillisecondsSinceEpoch(record.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(record.updatedAt),
  );
}

CashuLightningPayQuoteOperationRecord _payQuoteToRecord(
  CashuLightningPayQuoteRecord record,
) {
  return CashuLightningPayQuoteOperationRecord()
    ..ownerPubkey = record.owner.value
    ..quoteId = record.quoteId
    ..mintUrl = record.mintUrl.toString()
    ..amountSats = record.amount.value
    ..request = record.request
    ..feeReserveSats = record.feeReserve.value
    ..state = record.state.name
    ..expiry = record.expiry.millisecondsSinceEpoch
    ..createdAt = record.createdAt.millisecondsSinceEpoch
    ..updatedAt = record.updatedAt.millisecondsSinceEpoch
    ..amountSpentSats = record.amountSpent?.value
    ..feePaidSats = record.feePaid?.value
    ..paymentPreimage = record.paymentPreimage;
}

CashuLightningPayQuoteRecord _payQuoteFromRecord(
  CashuLightningPayQuoteOperationRecord record,
) {
  final amountSpentSats = record.amountSpentSats;
  final feePaidSats = record.feePaidSats;
  return CashuLightningPayQuoteRecord(
    owner: CashuAccountId.fromNostrPubkey(record.ownerPubkey),
    quoteId: record.quoteId,
    mintUrl: CashuMintUrl.parse(record.mintUrl),
    amount: CashuAmount.sats(record.amountSats),
    request: record.request,
    feeReserve: CashuAmount.sats(record.feeReserveSats),
    state: CashuQuoteState.values.byName(record.state),
    expiry: DateTime.fromMillisecondsSinceEpoch(record.expiry),
    createdAt: DateTime.fromMillisecondsSinceEpoch(record.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(record.updatedAt),
    amountSpent: amountSpentSats == null
        ? null
        : CashuAmount.sats(amountSpentSats),
    feePaid: feePaidSats == null ? null : CashuAmount.sats(feePaidSats),
    paymentPreimage: record.paymentPreimage,
  );
}
