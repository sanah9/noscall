import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/io_client.dart';
import 'package:noscall/core/call/messages/model/message_db_isar.dart';
import 'voice_attachment_cipher.dart';

/// Default timeout for voice file download (connection + idle).
const Duration _voiceDownloadTimeout = Duration(seconds: 30);

/// Manages local cache of voice message audio files using [flutter_cache_manager].
/// - [getOrDownload]: returns cached file or downloads once (library handles dedup by key).
/// - [bindLocalFile]: registers a local file as cache for a message (e.g. after send).
class VoiceCacheManager {
  VoiceCacheManager._();
  static final VoiceCacheManager instance = VoiceCacheManager._();

  static const String _cacheKey = 'voice_cache';
  static const Duration _stalePeriod = Duration(days: 14);
  static const int _maxCacheObjects = 300;

  static FileService _createVoiceFileService() {
    final ioClient = HttpClient()
      ..connectionTimeout = _voiceDownloadTimeout
      ..idleTimeout = _voiceDownloadTimeout
      ..findProxy = (Uri uri) => HttpClient.findProxyFromEnvironment(uri);
    return HttpFileService(httpClient: IOClient(ioClient));
  }

  /// Dedicated cache manager for voice files (lazy so unit tests that only validate input don't need path_provider/sqflite).
  CacheManager? _cacheManagerStore;
  CacheManager get _cacheManager => _cacheManagerStore ??= CacheManager(
    Config(
      _cacheKey,
      stalePeriod: _stalePeriod,
      maxNrOfCacheObjects: _maxCacheObjects,
      fileService: _createVoiceFileService(),
    ),
  );

  /// Test-only: override cache manager. Set in tests, null in production.
  BaseCacheManager? _testCacheManager;

  /// Test-only: set overrides for unit tests. Call [clearTestOverrides] in tearDown.
  static void setTestOverrides({BaseCacheManager? cacheManager}) {
    instance._testCacheManager = cacheManager;
  }

  /// Test-only: clear overrides after tests.
  static void clearTestOverrides() {
    instance._testCacheManager = null;
  }

  BaseCacheManager get _manager => _testCacheManager ?? _cacheManager;

  /// Ensures the cache manager is initialized so stale/max-object cleanup can run by package policy.
  void ensureInitialized() {
    _cacheManager;
  }

  /// Returns the cached file for [msg], or downloads and caches it.
  /// Same [messageId] shares one download (flutter_cache_manager deduplicates by key).
  Future<File> getOrDownload(MessageDBISAR msg) async {
    final messageId = msg.messageId;
    debugPrint('[VoiceCacheManager.getOrDownload] entry messageId=$messageId');
    if (messageId.isEmpty) {
      debugPrint('[VoiceCacheManager.getOrDownload] error: empty messageId');
      return Future.error(StateError('Voice message has no messageId'));
    }

    final payload =
        MessageDBISAR.parseVoiceContent(msg.decryptContent) ??
        MessageDBISAR.parseVoiceContent(msg.content);
    final url = payload?['url'];
    if (url is! String || url.isEmpty) {
      debugPrint(
        '[VoiceCacheManager.getOrDownload] error: no url messageId=$messageId',
      );
      return Future.error(StateError('Voice message has no url'));
    }

    if (payload!.containsKey('encryption')) {
      // Never fall back to treating an unknown encrypted format as plaintext.
      VoiceAttachmentCipher.validate(payload['encryption']);
      return _decryptDownload(messageId, url, payload['encryption']);
    }

    try {
      final file = await _manager.getSingleFile(url, key: messageId);
      final size = await file.length();
      debugPrint(
        '[VoiceCacheManager.getOrDownload] done messageId=$messageId path=${file.path} size=$size',
      );
      return file;
    } catch (e, st) {
      debugPrint(
        '[VoiceCacheManager.getOrDownload] error messageId=$messageId e=$e',
      );
      debugPrint('[VoiceCacheManager.getOrDownload] stackTrace=$st');
      rethrow;
    }
  }

  final Map<String, Future<File>> _decrypting = {};

  Future<File> _decryptDownload(String id, String url, Object? encryption) {
    return _decrypting.putIfAbsent(id, () async {
      try {
        final cached = await _manager.getFileFromCache('${id}_decrypted');
        if (cached != null && await cached.file.exists()) return cached.file;
        final file = await _manager.getSingleFile(url, key: id);
        if (await file.length() >
            VoiceAttachmentCipher.maxPlaintextBytes + 16) {
          throw const FormatException('Voice attachment too large');
        }
        final bytes = VoiceAttachmentCipher.decrypt(
          await file.readAsBytes(),
          encryption,
        );
        return await _manager.putFile(
          url,
          bytes,
          key: '${id}_decrypted',
          fileExtension: 'm4a',
        );
      } catch (_) {
        // Discard a failed download so Retry can fetch a fresh copy.
        await _manager.removeFile(id);
        rethrow;
      } finally {
        _decrypting.remove(id);
      }
    });
  }

  /// Binds a local file as the cache for the given message (e.g. after sending).
  /// Copies [localFilePath] into the cache so [getOrDownload] will return it.
  Future<void> bindLocalFile({
    required String messageId,
    required String url,
    required String localFilePath,
    bool encrypted = false,
  }) async {
    if (messageId.isEmpty) return;
    final source = File(localFilePath);
    if (!await source.exists()) return;
    final fileBytes = await source.readAsBytes();
    await _manager.putFile(
      url,
      fileBytes,
      key: encrypted ? '${messageId}_decrypted' : messageId,
      fileExtension: 'm4a',
    );
  }

  /// Removes cached file for [messageId]. No-op if not cached.
  Future<void> deleteCacheForMessage(String messageId) async {
    if (messageId.isEmpty) return;
    await _manager.removeFile(messageId);
    await _manager.removeFile('${messageId}_decrypted');
  }

  /// Removes cache for a list of message IDs.
  Future<void> deleteCacheForMessages(Iterable<String> messageIds) async {
    for (final id in messageIds) {
      if (id.isEmpty) continue;
      await deleteCacheForMessage(id);
    }
  }

  /// Clears all cached voice files.
  Future<void> clearAllCache() async {
    await _manager.emptyCache();
  }
}
