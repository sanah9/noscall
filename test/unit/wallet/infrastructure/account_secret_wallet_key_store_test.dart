import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/core/account/account_secret_store.dart';
import 'package:noscall/wallet/infrastructure/security/account_secret_wallet_key_store.dart';

void main() {
  test('stores wallet mnemonic in account secret storage', () async {
    final secretStore = _FakeAccountSecretStore();
    final keyStore = AccountSecretWalletKeyStore(secretStore: secretStore);

    await keyStore.writeMnemonic('seed-reference', ' word1 word2 ');

    expect(keyStore.isProductionReady, isTrue);
    expect(secretStore.values, {
      'wallet.seed-reference.mnemonic': 'word1 word2',
    });
    expect(await keyStore.readMnemonic('seed-reference'), 'word1 word2');

    await keyStore.deleteMnemonic('seed-reference');

    expect(await keyStore.readMnemonic('seed-reference'), isNull);
  });

  test('rejects empty references', () async {
    final keyStore = AccountSecretWalletKeyStore(
      secretStore: _FakeAccountSecretStore(),
    );

    expect(() => keyStore.readMnemonic(''), throwsA(isA<ArgumentError>()));
  });
}

final class _FakeAccountSecretStore implements AccountSecretStore {
  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
