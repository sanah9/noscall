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
