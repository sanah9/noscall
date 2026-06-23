/// Persistence boundary for Cashu wallet mnemonic material.
///
/// Production implementations must use platform-protected storage. The
/// wallet module must never put mnemonic material in Isar, SharedPreferences,
/// logs, analytics, or crash reports.
abstract interface class WalletKeyStore {
  bool get isProductionReady;

  Future<String?> readMnemonic(String reference);

  Future<void> writeMnemonic(String reference, String mnemonic);

  Future<void> deleteMnemonic(String reference);
}
