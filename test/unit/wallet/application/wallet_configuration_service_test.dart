import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/application/wallet_configuration_service.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/wallet_configuration.dart';

void main() {
  late _MemoryWalletConfigurationRepository repository;
  late DateTime now;
  late WalletConfigurationService service;

  setUp(() {
    repository = _MemoryWalletConfigurationRepository();
    now = DateTime.utc(2026, 6, 20, 8);
    service = WalletConfigurationService(
      repository: repository,
      clock: () => now,
    );
  });

  test('creates one rebuildable projection for an account', () async {
    final owner = _account('a');

    final first = await service.ensure(owner);
    now = now.add(const Duration(hours: 1));
    final second = await service.ensure(owner);

    expect(first.owner, owner);
    expect(first.seedReference, owner.seedReference);
    expect(first.backupStatus, WalletBackupStatus.notShown);
    expect(first.createdAt, DateTime.utc(2026, 6, 20, 8));
    expect(second.createdAt, first.createdAt);
    expect(repository.saveCalls, 1);
  });

  test('updates backup status without changing creation identity', () async {
    final owner = _account('b');
    final created = await service.ensure(owner);
    now = now.add(const Duration(minutes: 5));

    final updated = await service.updateBackupStatus(
      owner,
      WalletBackupStatus.skipped,
    );

    expect(updated.backupStatus, WalletBackupStatus.skipped);
    expect(updated.createdAt, created.createdAt);
    expect(updated.updatedAt, now);
    expect(updated.seedReference, created.seedReference);
  });

  test('does not invent configuration during a backup update', () async {
    expect(
      service.updateBackupStatus(_account('c'), WalletBackupStatus.confirmed),
      throwsStateError,
    );
  });
}

CashuAccountId _account(String character) =>
    CashuAccountId.fromNostrPubkey(character * 64);

final class _MemoryWalletConfigurationRepository
    implements WalletConfigurationRepository {
  final Map<CashuAccountId, WalletConfiguration> values = {};
  int saveCalls = 0;

  @override
  Future<WalletConfiguration?> find(CashuAccountId owner) async =>
      values[owner];

  @override
  Future<void> save(WalletConfiguration configuration) async {
    saveCalls++;
    values[configuration.owner] = configuration;
  }
}
