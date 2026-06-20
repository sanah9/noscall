import 'dart:collection';

import 'cashu_models.dart';

/// Source for optional product-configured Mint suggestions.
///
/// Production currently uses [EmptyDefaultMintProvider]. A configured provider
/// can be injected later without changing wallet creation or Mint UI code.
abstract interface class DefaultMintProvider {
  Future<List<CashuMintUrl>> load();
}

final class EmptyDefaultMintProvider implements DefaultMintProvider {
  const EmptyDefaultMintProvider();

  @override
  Future<List<CashuMintUrl>> load() async => const [];
}

/// Configuration-backed implementation with no built-in URLs.
final class ConfiguredDefaultMintProvider implements DefaultMintProvider {
  ConfiguredDefaultMintProvider(Iterable<CashuMintUrl> mintUrls)
    : _mintUrls = List.unmodifiable(LinkedHashSet.of(mintUrls));

  final List<CashuMintUrl> _mintUrls;

  @override
  Future<List<CashuMintUrl>> load() async => _mintUrls;
}

final class MintCapabilityDecision {
  MintCapabilityDecision({
    required this.canUseCashu,
    required this.canMintBolt11,
    required this.canMeltBolt11,
    required Set<CashuNut> missingCoreNuts,
  }) : missingCoreNuts = UnmodifiableSetView(Set.of(missingCoreNuts));

  final bool canUseCashu;
  final bool canMintBolt11;
  final bool canMeltBolt11;
  final Set<CashuNut> missingCoreNuts;
}

/// First-release capability policy. It reports feature availability without
/// silently inventing support for a Mint that does not advertise it.
final class MintCapabilityPolicy {
  const MintCapabilityPolicy();

  static const requiredCoreNuts = <CashuNut>{
    CashuNut.nut00,
    CashuNut.nut01,
    CashuNut.nut02,
    CashuNut.nut03,
    CashuNut.nut06,
    CashuNut.nut07,
    CashuNut.nut09,
  };

  MintCapabilityDecision evaluate(CashuMintSnapshot mint) {
    final missingCoreNuts = requiredCoreNuts.difference(mint.supportedNuts);
    final canUseCashu = mint.supportsSat && missingCoreNuts.isEmpty;
    final canMintBolt11 =
        canUseCashu &&
        mint.supportsBolt11Mint &&
        mint.supportedNuts.containsAll({CashuNut.nut04, CashuNut.nut23});
    final canMeltBolt11 =
        canUseCashu &&
        mint.supportsBolt11Melt &&
        mint.supportedNuts.containsAll({
          CashuNut.nut05,
          CashuNut.nut08,
          CashuNut.nut23,
        });

    return MintCapabilityDecision(
      canUseCashu: canUseCashu,
      canMintBolt11: canMintBolt11,
      canMeltBolt11: canMeltBolt11,
      missingCoreNuts: missingCoreNuts,
    );
  }
}
