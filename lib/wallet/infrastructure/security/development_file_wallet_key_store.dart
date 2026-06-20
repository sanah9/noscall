import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../domain/wallet_key_store.dart';

/// Plaintext seed storage for automated tests and development builds only.
///
/// Callers must explicitly opt in before a wallet session accepts this store.
/// It must be replaced by Keychain/Keystore storage before real-money release.
final class DevelopmentFileWalletKeyStore implements WalletKeyStore {
  DevelopmentFileWalletKeyStore(this.directory);

  final Directory directory;

  @override
  bool get isProductionReady => false;

  File _fileFor(String reference) {
    if (reference.isEmpty) {
      throw ArgumentError.value(reference, 'reference', 'Cannot be empty');
    }
    final digest = sha256.convert(utf8.encode(reference));
    return File('${directory.path}/$digest.mnemonic.dev');
  }

  @override
  Future<String?> readMnemonic(String reference) async {
    final file = _fileFor(reference);
    if (!await file.exists()) return null;

    final mnemonic = (await file.readAsString()).trim();
    if (mnemonic.isEmpty) {
      throw StateError('Development wallet seed file is empty');
    }
    return mnemonic;
  }

  @override
  Future<void> writeMnemonic(String reference, String mnemonic) async {
    final normalized = mnemonic.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(mnemonic, 'mnemonic', 'Cannot be empty');
    }

    await directory.create(recursive: true);
    final file = _fileFor(reference);
    if (await file.exists()) {
      throw StateError('Wallet seed already exists');
    }

    final temporary = File('${file.path}.tmp');
    try {
      await temporary.writeAsString(normalized, flush: true);
      await temporary.rename(file.path);
    } finally {
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }

  @override
  Future<void> deleteMnemonic(String reference) async {
    final file = _fileFor(reference);
    if (await file.exists()) await file.delete();
  }
}
