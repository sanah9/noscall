import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/core/call/messages/voice_attachment_cipher.dart';

void main() {
  final audio = Uint8List.fromList(List.generate(1025, (i) => i % 256));

  test('round trips audio and generates independent keys and nonces', () {
    final a = VoiceAttachmentCipher.encrypt(audio);
    final b = VoiceAttachmentCipher.encrypt(audio);
    expect(a.bytes, isNot(audio));
    expect(a.encryption['key'], isNot(b.encryption['key']));
    expect(a.encryption['nonce'], isNot(b.encryption['nonce']));
    expect(VoiceAttachmentCipher.decrypt(a.bytes, a.encryption), audio);
  });

  test('rejects tampering, truncated tag, and incorrect key', () {
    final a = VoiceAttachmentCipher.encrypt(audio);
    final corrupt = Uint8List.fromList(a.bytes)..[0] ^= 1;
    for (final bytes in [corrupt, a.bytes.sublist(0, a.bytes.length - 1)]) {
      expect(
        () => VoiceAttachmentCipher.decrypt(bytes, a.encryption),
        throwsFormatException,
      );
    }
    expect(
      () => VoiceAttachmentCipher.decrypt(a.bytes, {
        ...a.encryption,
        'key': base64Encode(Uint8List(32)),
      }),
      throwsFormatException,
    );
  });

  test(
    'rejects unknown formats and malformed encryption without downgrade',
    () {
      final a = VoiceAttachmentCipher.encrypt(audio);
      for (final metadata in [
        null,
        {},
        {...a.encryption, 'version': 2},
        {...a.encryption, 'algorithm': 'AES-CBC'},
        {...a.encryption, 'nonce': 'invalid'},
        {...a.encryption, 'key': base64Encode(Uint8List(16))},
      ]) {
        expect(
          () => VoiceAttachmentCipher.decrypt(a.bytes, metadata),
          throwsFormatException,
        );
      }
    },
  );

  test('rejects empty and oversized recordings', () {
    expect(
      () => VoiceAttachmentCipher.encrypt(Uint8List(0)),
      throwsFormatException,
    );
    expect(
      () => VoiceAttachmentCipher.encrypt(
        Uint8List(VoiceAttachmentCipher.maxPlaintextBytes + 1),
      ),
      throwsFormatException,
    );
  });
}
