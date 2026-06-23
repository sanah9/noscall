/// Safe error exposed above the Cashu SDK boundary.
///
/// It deliberately stores neither the original SDK exception nor user input,
/// because either may contain a token, quote identifier, or proof secret.
final class CashuProtocolException implements Exception {
  const CashuProtocolException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'CashuProtocolException($code): $message';
}

final class UnsupportedMintException implements Exception {
  UnsupportedMintException({
    required this.supportsSat,
    required Set<int> missingNutNumbers,
  }) : missingNutNumbers = Set.unmodifiable(missingNutNumbers);

  final bool supportsSat;
  final Set<int> missingNutNumbers;

  @override
  String toString() => 'UnsupportedMintException: Mint capabilities rejected';
}

final class MintHasBalanceException implements Exception {
  const MintHasBalanceException(this.balanceSats);

  final int balanceSats;
}
