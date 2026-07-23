import 'package:flutter/services.dart';

abstract class AccountSecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class MethodChannelAccountSecretStore implements AccountSecretStore {
  const MethodChannelAccountSecretStore();

  static const MethodChannel _channel = MethodChannel(
    'sh.noscall.account_secrets',
  );

  @override
  Future<String?> read(String key) async {
    return _channel.invokeMethod<String>('read', {'key': key});
  }

  @override
  Future<void> write(String key, String value) async {
    await _channel.invokeMethod<void>('write', {'key': key, 'value': value});
  }

  @override
  Future<void> delete(String key) async {
    await _channel.invokeMethod<void>('delete', {'key': key});
  }
}

class AccountSecretKeys {
  const AccountSecretKeys._();

  static String privateKeyPassword(String pubkey) {
    return 'account.$pubkey.private_key_password';
  }

  static String remoteSignerClientPrivateKey(String pubkey) {
    return 'account.$pubkey.remote_signer_client_private_key';
  }
}
