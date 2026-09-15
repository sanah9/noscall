import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Versioned audio envelope. The descriptor travels only inside the encrypted DM.
class VoiceAttachmentCipher {
  static const maxPlaintextBytes = 5 * 1024 * 1024 - 16;
  static const algorithm = 'AES-256-GCM';
  static final _aad = Uint8List.fromList(utf8.encode('noscall:voice:v1'));

  static ({Uint8List bytes, Map<String, dynamic> encryption}) encrypt(
    Uint8List plaintext,
  ) {
    if (plaintext.isEmpty || plaintext.length > maxPlaintextBytes) {
      throw const FormatException('Invalid voice attachment size');
    }
    final random = Random.secure();
    final key = Uint8List.fromList(
      List.generate(32, (_) => random.nextInt(256)),
    );
    final nonce = Uint8List.fromList(
      List.generate(12, (_) => random.nextInt(256)),
    );
    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), 128, nonce, _aad));
    return (
      bytes: cipher.process(plaintext),
      encryption: {
        'version': 1,
        'algorithm': algorithm,
        'key': base64Encode(key),
        'nonce': base64Encode(nonce),
      },
    );
  }

  static ({Uint8List key, Uint8List nonce}) validate(Object? descriptor) {
    if (descriptor is! Map ||
        descriptor['version'] != 1 ||
        descriptor['algorithm'] != algorithm ||
        descriptor['key'] is! String ||
        descriptor['nonce'] is! String) {
      throw const FormatException('Unsupported voice encryption');
    }
    final key = base64Decode(descriptor['key'] as String);
    final nonce = base64Decode(descriptor['nonce'] as String);
    if (key.length != 32 || nonce.length != 12) {
      throw const FormatException('Invalid voice encryption parameters');
    }
    return (key: key, nonce: nonce);
  }

  static Uint8List decrypt(Uint8List ciphertext, Object? descriptor) {
    final parameters = validate(descriptor);
    if (ciphertext.length <= 16 || ciphertext.length > maxPlaintextBytes + 16) {
      throw const FormatException('Invalid encrypted voice size');
    }
    try {
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          false,
          AEADParameters(
            KeyParameter(parameters.key),
            128,
            parameters.nonce,
            _aad,
          ),
        );
      return cipher.process(ciphertext);
    } on InvalidCipherTextException {
      throw const FormatException('Voice attachment authentication failed');
    }
  }
}
