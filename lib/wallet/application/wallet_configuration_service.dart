import '../domain/cashu_account_id.dart';
import '../domain/wallet_configuration.dart';

typedef WalletClock = DateTime Function();

/// Maintains the rebuildable noscall projection for an account wallet.
///
/// This service never reads or writes proofs, balances, quotes, or Cashu
/// transactions. Those remain authoritative in the account's CDK database.
final class WalletConfigurationService {
  WalletConfigurationService({
    required WalletConfigurationRepository repository,
    WalletClock? clock,
  }) : _repository = repository,
       _clock = clock ?? DateTime.now;

  static const currentSchemaVersion = 1;

  final WalletConfigurationRepository _repository;
  final WalletClock _clock;

  Future<WalletConfiguration> ensure(CashuAccountId owner) async {
    final existing = await _repository.find(owner);
    if (existing != null) {
      if (existing.seedReference != owner.seedReference) {
        throw StateError('Cashu wallet seed reference does not match owner');
      }
      return existing;
    }

    final now = _clock();
    final configuration = WalletConfiguration(
      owner: owner,
      seedReference: owner.seedReference,
      backupStatus: WalletBackupStatus.notShown,
      createdAt: now,
      updatedAt: now,
      schemaVersion: currentSchemaVersion,
    );
    await _repository.save(configuration);
    return configuration;
  }

  Future<WalletConfiguration> updateBackupStatus(
    CashuAccountId owner,
    WalletBackupStatus status,
  ) async {
    final existing = await _repository.find(owner);
    if (existing == null) {
      throw StateError('Cashu wallet configuration does not exist');
    }
    final updated = existing.copyWith(
      backupStatus: status,
      updatedAt: _clock(),
    );
    await _repository.save(updated);
    return updated;
  }
}
