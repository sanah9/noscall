import '../domain/cashu_account_id.dart';
import '../domain/cashu_engine.dart';
import '../domain/cashu_models.dart';
import '../domain/mint_configuration.dart';
import '../domain/wallet_configuration.dart';
import '../domain/wallet_errors.dart';

typedef MintRegistryClock = DateTime Function();

final class MintRegistrationPreview {
  const MintRegistrationPreview({
    required this.owner,
    required this.snapshot,
    required this.capabilities,
    required this.source,
    required this.enabledByDefault,
    this.configuredDisplayName,
  });

  final CashuAccountId owner;
  final CashuMintSnapshot snapshot;
  final MintCapabilityDecision capabilities;
  final MintConfigurationSource source;
  final bool enabledByDefault;
  final String? configuredDisplayName;
}

/// Account-scoped source of product Mint configuration.
///
/// Validation is deliberately separate from confirmation so UI can show Mint
/// metadata and custody risk before anything becomes enabled.
final class MintRegistryService {
  MintRegistryService({
    required CashuMintInspector inspector,
    required MintConfigurationRepository repository,
    DefaultMintProvider defaultMintProvider = const EmptyDefaultMintProvider(),
    MintCapabilityPolicy capabilityPolicy = const MintCapabilityPolicy(),
    MintRegistryClock? clock,
  }) : _inspector = inspector,
       _repository = repository,
       _defaultMintProvider = defaultMintProvider,
       _capabilityPolicy = capabilityPolicy,
       _clock = clock ?? DateTime.now;

  final CashuMintInspector _inspector;
  final MintConfigurationRepository _repository;
  final DefaultMintProvider _defaultMintProvider;
  final MintCapabilityPolicy _capabilityPolicy;
  final MintRegistryClock _clock;

  Future<List<MintConfiguration>> list(CashuAccountId owner) =>
      _repository.list(owner);

  Future<List<DefaultMintSuggestion>> loadConfiguredSuggestions() =>
      _defaultMintProvider.load();

  Future<MintRegistrationPreview> validateManual(
    CashuAccountId owner,
    String input,
  ) {
    late final CashuMintUrl url;
    try {
      url = CashuMintUrl.parse(input);
    } on FormatException {
      throw const CashuProtocolException(
        'invalid_mint_url',
        'Enter a valid HTTPS Mint URL',
      );
    }
    return _validate(
      owner: owner,
      url: url,
      source: MintConfigurationSource.manual,
      enabledByDefault: true,
    );
  }

  Future<MintRegistrationPreview> validateConfigured(
    CashuAccountId owner,
    DefaultMintSuggestion suggestion,
  ) {
    return _validate(
      owner: owner,
      url: suggestion.url,
      source: MintConfigurationSource.configured,
      enabledByDefault: suggestion.enabled,
      configuredDisplayName: suggestion.displayName,
    );
  }

  Future<MintConfiguration> confirm(MintRegistrationPreview preview) async {
    _ensureSupported(preview.snapshot, preview.capabilities);
    final existing = await _repository.find(
      preview.owner,
      preview.snapshot.url,
    );
    final configuration = MintConfiguration(
      owner: preview.owner,
      url: preview.snapshot.url,
      name:
          preview.snapshot.name ??
          preview.configuredDisplayName ??
          existing?.name,
      description: preview.snapshot.description ?? existing?.description,
      enabled: preview.enabledByDefault,
      source: existing?.source ?? preview.source,
      supportedNuts: preview.snapshot.supportedNuts,
      units: const ['sat'],
      lastSyncAt: _clock(),
    );
    await _repository.save(configuration);
    return configuration;
  }

  Future<MintConfiguration> refresh(
    CashuAccountId owner,
    CashuMintUrl url,
  ) async {
    final existing = await _requireExisting(owner, url);
    return _refresh(existing, enableWhenSupported: existing.enabled);
  }

  Future<MintConfiguration> setEnabled(
    CashuAccountId owner,
    CashuMintUrl url,
    bool enabled,
  ) async {
    final existing = await _requireExisting(owner, url);
    if (enabled) {
      return _refresh(existing, enableWhenSupported: true);
    }
    final updated = existing.copyWith(enabled: false);
    await _repository.save(updated);
    return updated;
  }

  Future<void> remove(CashuAccountId owner, CashuMintUrl url) async {
    await _requireExisting(owner, url);
    await _repository.delete(owner, url);
  }

  Future<MintRegistrationPreview> _validate({
    required CashuAccountId owner,
    required CashuMintUrl url,
    required MintConfigurationSource source,
    required bool enabledByDefault,
    String? configuredDisplayName,
  }) async {
    final snapshot = await _inspector.inspectMint(url);
    final capabilities = _capabilityPolicy.evaluate(snapshot);
    _ensureSupported(snapshot, capabilities);
    return MintRegistrationPreview(
      owner: owner,
      snapshot: snapshot,
      capabilities: capabilities,
      source: source,
      enabledByDefault: enabledByDefault,
      configuredDisplayName: configuredDisplayName,
    );
  }

  Future<MintConfiguration> _refresh(
    MintConfiguration existing, {
    required bool enableWhenSupported,
  }) async {
    try {
      final snapshot = await _inspector.inspectMint(existing.url);
      final capabilities = _capabilityPolicy.evaluate(snapshot);
      _ensureSupported(snapshot, capabilities);
      final updated = existing.copyWith(
        name: snapshot.name,
        description: snapshot.description,
        enabled: enableWhenSupported,
        supportedNuts: snapshot.supportedNuts,
        units: const ['sat'],
        lastSyncAt: _clock(),
        clearLastError: true,
      );
      await _repository.save(updated);
      return updated;
    } on CashuProtocolException catch (error) {
      await _saveRefreshFailure(existing, error.code);
      rethrow;
    } on UnsupportedMintException {
      await _saveRefreshFailure(existing, 'unsupported_mint', disable: true);
      rethrow;
    }
  }

  Future<void> _saveRefreshFailure(
    MintConfiguration existing,
    String errorCode, {
    bool disable = false,
  }) {
    return _repository.save(
      existing.copyWith(
        enabled: disable ? false : existing.enabled,
        lastError: errorCode,
      ),
    );
  }

  Future<MintConfiguration> _requireExisting(
    CashuAccountId owner,
    CashuMintUrl url,
  ) async {
    final existing = await _repository.find(owner, url);
    if (existing == null) {
      throw StateError('Mint configuration does not exist');
    }
    return existing;
  }

  void _ensureSupported(
    CashuMintSnapshot snapshot,
    MintCapabilityDecision decision,
  ) {
    if (decision.canUseCashu) return;
    throw UnsupportedMintException(
      supportsSat: snapshot.supportsSat,
      missingNutNumbers: decision.missingCoreNuts
          .map((nut) => nut.number)
          .toSet(),
    );
  }
}
