/// Stable wallet owner derived from a Nostr public key.
final class CashuAccountId {
  CashuAccountId._(this.value);

  factory CashuAccountId.fromNostrPubkey(String pubkey) {
    final normalized = pubkey.trim().toLowerCase();
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(normalized)) {
      throw const FormatException(
        'Cashu wallet account requires a 32-byte hex Nostr public key',
      );
    }
    return CashuAccountId._(normalized);
  }

  final String value;

  String get seedReference => 'cashu-wallet-seed-v1:$value';

  @override
  bool operator ==(Object other) =>
      other is CashuAccountId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
