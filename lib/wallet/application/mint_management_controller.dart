import '../domain/cashu_account_id.dart';
import '../domain/cashu_models.dart';
import '../domain/mint_configuration.dart';
import '../domain/wallet_configuration.dart';
import 'mint_registry_service.dart';

final class MintManagementSnapshot {
  MintManagementSnapshot({
    required Iterable<MintConfiguration> mints,
    required Iterable<DefaultMintSuggestion> suggestions,
  }) : mints = List.unmodifiable(mints),
       suggestions = List.unmodifiable(suggestions);

  final List<MintConfiguration> mints;
  final List<DefaultMintSuggestion> suggestions;
}

abstract interface class MintManagementController {
  Future<MintManagementSnapshot> load();

  Future<MintRegistrationPreview> validateManual(String input);

  Future<MintRegistrationPreview> validateSuggestion(
    DefaultMintSuggestion suggestion,
  );

  Future<MintManagementSnapshot> confirm(MintRegistrationPreview preview);

  Future<MintManagementSnapshot> setEnabled(CashuMintUrl url, bool enabled);

  Future<MintManagementSnapshot> refresh(CashuMintUrl url);

  Future<MintManagementSnapshot> remove(CashuMintUrl url);

  Future<void> dispose();
}

final class AccountMintManagementController
    implements MintManagementController {
  AccountMintManagementController({
    required CashuAccountId accountId,
    required MintRegistryService registry,
    Future<void> Function()? onDispose,
  }) : _accountId = accountId,
       _registry = registry,
       _onDispose = onDispose;

  final CashuAccountId _accountId;
  final MintRegistryService _registry;
  final Future<void> Function()? _onDispose;
  bool _disposed = false;

  @override
  Future<MintManagementSnapshot> load() async {
    final mints = await _registry.list(_accountId);
    final configuredUrls = mints.map((mint) => mint.url).toSet();
    final suggestions = (await _registry.loadConfiguredSuggestions()).where(
      (suggestion) => !configuredUrls.contains(suggestion.url),
    );
    return MintManagementSnapshot(mints: mints, suggestions: suggestions);
  }

  @override
  Future<MintRegistrationPreview> validateManual(String input) =>
      _registry.validateManual(_accountId, input);

  @override
  Future<MintRegistrationPreview> validateSuggestion(
    DefaultMintSuggestion suggestion,
  ) => _registry.validateConfigured(_accountId, suggestion);

  @override
  Future<MintManagementSnapshot> confirm(
    MintRegistrationPreview preview,
  ) async {
    await _registry.confirm(preview);
    return load();
  }

  @override
  Future<MintManagementSnapshot> setEnabled(
    CashuMintUrl url,
    bool enabled,
  ) async {
    await _registry.setEnabled(_accountId, url, enabled);
    return load();
  }

  @override
  Future<MintManagementSnapshot> refresh(CashuMintUrl url) async {
    await _registry.refresh(_accountId, url);
    return load();
  }

  @override
  Future<MintManagementSnapshot> remove(CashuMintUrl url) async {
    await _registry.remove(_accountId, url);
    return load();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _onDispose?.call();
  }
}
