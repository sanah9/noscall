import 'dart:collection';

import 'cashu_account_id.dart';
import 'cashu_models.dart';

enum WalletBackupStatus { notShown, shown, skipped, confirmed }

final class WalletConfiguration {
  const WalletConfiguration({
    required this.owner,
    required this.seedReference,
    required this.backupStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.schemaVersion,
  });

  final CashuAccountId owner;
  final String seedReference;
  final WalletBackupStatus backupStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int schemaVersion;

  WalletConfiguration copyWith({
    WalletBackupStatus? backupStatus,
    DateTime? updatedAt,
  }) {
    return WalletConfiguration(
      owner: owner,
      seedReference: seedReference,
      backupStatus: backupStatus ?? this.backupStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      schemaVersion: schemaVersion,
    );
  }
}

abstract interface class WalletConfigurationRepository {
  Future<WalletConfiguration?> find(CashuAccountId owner);

  Future<void> save(WalletConfiguration configuration);
}

enum MintConfigurationSource { manual, configured }

final class MintConfiguration {
  MintConfiguration({
    required this.owner,
    required this.url,
    required this.enabled,
    required this.source,
    required Set<CashuNut> supportedNuts,
    required Iterable<String> units,
    required this.lastSyncAt,
    this.name,
    this.description,
    this.lastError,
  }) : supportedNuts = UnmodifiableSetView(Set.of(supportedNuts)),
       units = List.unmodifiable(units);

  final CashuAccountId owner;
  final CashuMintUrl url;
  final String? name;
  final String? description;
  final bool enabled;
  final MintConfigurationSource source;
  final Set<CashuNut> supportedNuts;
  final List<String> units;
  final DateTime lastSyncAt;
  final String? lastError;

  MintConfiguration copyWith({
    bool? enabled,
    Set<CashuNut>? supportedNuts,
    Iterable<String>? units,
    DateTime? lastSyncAt,
    String? name,
    String? description,
    String? lastError,
    bool clearLastError = false,
  }) {
    return MintConfiguration(
      owner: owner,
      url: url,
      name: name ?? this.name,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
      source: source,
      supportedNuts: supportedNuts ?? this.supportedNuts,
      units: units ?? this.units,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastError: clearLastError ? null : lastError ?? this.lastError,
    );
  }
}

abstract interface class MintConfigurationRepository {
  Future<MintConfiguration?> find(CashuAccountId owner, CashuMintUrl url);

  Future<List<MintConfiguration>> list(CashuAccountId owner);

  Future<void> save(MintConfiguration configuration);

  Future<void> delete(CashuAccountId owner, CashuMintUrl url);
}
