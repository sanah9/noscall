import 'package:isar/isar.dart';

part 'wallet_configuration_isar.g.dart';

@collection
class CashuWalletConfigurationRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String ownerPubkey = '';

  String seedReference = '';
  String backupStatus = '';
  int createdAt = 0;
  int updatedAt = 0;
  int schemaVersion = 1;
}

@collection
class CashuMintConfigurationRecord {
  Id id = Isar.autoIncrement;

  @Index(
    composite: [CompositeIndex('normalizedUrl')],
    unique: true,
    replace: true,
  )
  String ownerPubkey = '';

  String normalizedUrl = '';
  String? name;
  String? description;
  bool enabled = true;
  String source = '';
  List<int> supportedNutNumbers = const [];
  List<String> units = const [];
  int lastSyncAt = 0;
  String? lastError;
}

@collection
class CashuTokenSendOperationRecord {
  Id id = Isar.autoIncrement;

  @Index(
    composite: [CompositeIndex('operationId')],
    unique: true,
    replace: true,
  )
  String ownerPubkey = '';

  String operationId = '';
  String mintUrl = '';
  int amountSats = 0;
  String state = '';
  String? memo;
  int createdAt = 0;
  int updatedAt = 0;
}

@collection
class CashuLightningReceiveQuoteOperationRecord {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('quoteId')], unique: true, replace: true)
  String ownerPubkey = '';

  String quoteId = '';
  String mintUrl = '';
  int amountSats = 0;
  String request = '';
  String state = '';
  int expiry = 0;
  int createdAt = 0;
  int updatedAt = 0;
}

@collection
class CashuLightningPayQuoteOperationRecord {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('quoteId')], unique: true, replace: true)
  String ownerPubkey = '';

  String quoteId = '';
  String mintUrl = '';
  int amountSats = 0;
  String request = '';
  int feeReserveSats = 0;
  String state = '';
  int expiry = 0;
  int createdAt = 0;
  int updatedAt = 0;
  int? amountSpentSats;
  int? feePaidSats;
  String? paymentPreimage;
}
