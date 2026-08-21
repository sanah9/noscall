import 'package:noscall/core/account/account_secret_store.dart';

import '../../domain/wallet_key_store.dart';

/// Wallet mnemonic storage backed by platform-protected account secret storage.
final class AccountSecretWalletKeyStore implements WalletKeyStore {
  const AccountSecretWalletKeyStore({
    AccountSecretStore secretStore = const MethodChannelAccountSecretStore(),
  }) : _secretStore = secretStore;

  final AccountSecretStore _secretStore;

  @override
  bool get isProductionReady => true;

  @override
  Future<String?> readMnemonic(String reference) {
    return _secretStore.read(_key(reference));
  }

  @override
  Future<void> writeMnemonic(String reference, String mnemonic) {
    return _secretStore.write(_key(reference), mnemonic.trim());
  }

  @override
  Future<void> deleteMnemonic(String reference) {
    return _secretStore.delete(_key(reference));
  }

  String _key(String reference) {
    if (reference.isEmpty) {
      throw ArgumentError.value(reference, 'reference', 'Cannot be empty');
    }
    return 'wallet.$reference.mnemonic';
  }
}
