import 'dart:io';

import 'package:noscall/core/call/messages/voice_attachment_cipher.dart';
import 'package:noscall/utils/file_upload_manager.dart';

class VoiceAttachmentUpload {
  static Future<({String url, Map<String, dynamic> encryption})> upload(
    File recording, {
    void Function(double)? onProgress,
  }) async {
    final size = await recording.length();
    if (size == 0 || size > VoiceAttachmentCipher.maxPlaintextBytes) {
      throw const FormatException('Recording too large or empty');
    }
    final encrypted = VoiceAttachmentCipher.encrypt(
      await recording.readAsBytes(),
    );
    final directory = await Directory.systemTemp.createTemp('noscall_voice_');
    try {
      final file = File('${directory.path}/attachment.bin');
      await file.writeAsBytes(encrypted.bytes, flush: true);
      final url = await FileUploadManager.uploadFile(
        file,
        onProgress: onProgress,
      );
      if (url == null || url.isEmpty) {
        throw const HttpException('Upload failed');
      }
      return (url: url, encryption: encrypted.encryption);
    } finally {
      await directory.delete(recursive: true);
    }
  }
}
