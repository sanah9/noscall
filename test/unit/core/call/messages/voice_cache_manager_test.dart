import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/core/call/messages/model/messageDB_isar.dart';
import 'package:noscall/core/call/messages/voice_cache_manager.dart';

/// Fake that only records [removeFile] calls. Used to test "deleteCacheForMessage calls removeFile"
/// without needing path_provider/sqflite.
class FakeVoiceCacheManager implements BaseCacheManager {
  FakeVoiceCacheManager(this.baseDir);

  final io.Directory baseDir;
  final _fs = const LocalFileSystem();
  final Map<String, File> _filesByKey = {};
  final List<String> removeFileCalls = [];
  int emptyCacheCalls = 0;

  String _pathForKey(String key, String fileExtension) =>
      '${baseDir.path}/$key.$fileExtension';

  @override
  Future<void> removeFile(String key) async {
    removeFileCalls.add(key);
    final existing = _filesByKey.remove(key);
    if (existing != null && await existing.exists()) {
      await existing.delete();
    }
  }

  @override
  Future<void> emptyCache() async {
    emptyCacheCalls++;
    final files = _filesByKey.values.toList();
    _filesByKey.clear();
    for (final file in files) {
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<File> getSingleFile(String url,
      {String key = '', Map<String, String> headers = const {}}) async {
    final cacheKey = key.isNotEmpty ? key : url;
    final file = _filesByKey[cacheKey];
    if (file == null || !await file.exists()) {
      throw StateError('No cached file for key: $cacheKey');
    }
    return file;
  }

  @override
  Future<FileInfo?> getFileFromCache(String key,
      {bool ignoreMemCache = false}) async {
    final file = _filesByKey[key];
    if (file == null || !await file.exists()) return null;
    return FileInfo(
      file,
      FileSource.Cache,
      DateTime.now().add(const Duration(days: 1)),
      key,
    );
  }

  @override
  Future<FileInfo?> getFileFromMemory(String key) async {
    return getFileFromCache(key);
  }

  @override
  Future<FileInfo> downloadFile(String url,
      {String? key,
      Map<String, String>? authHeaders,
      bool force = false}) async {
    throw UnimplementedError();
  }

  @override
  Stream<FileResponse> getFileStream(String url,
      {String? key, Map<String, String>? headers, bool withProgress = false}) {
    throw UnimplementedError();
  }

  @override
  Future<File> putFile(String url, Uint8List fileBytes,
      {String? key,
      String? eTag,
      Duration? maxAge,
      String fileExtension = 'file'}) async {
    final cacheKey = key ?? url;
    final file = _fs.file(_pathForKey(cacheKey, fileExtension));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(fileBytes);
    _filesByKey[cacheKey] = file;
    return file;
  }

  @override
  Future<File> putFileStream(String url, Stream<List<int>> source,
      {String? key,
      String? eTag,
      Duration? maxAge,
      String fileExtension = 'file'}) async {
    throw UnimplementedError();
  }

  @override
  Stream<FileInfo> getFile(String url,
      {String? key, Map<String, String>? headers}) {
    throw UnimplementedError();
  }
}

MessageDBISAR voiceMessage({
  required String messageId,
  required String url,
  int durationSeconds = 10,
  String? decryptContent,
}) {
  final payload = {
    'contentType': 'voice',
    'url': url,
    'durationSeconds': durationSeconds,
    'mimeType': 'audio/mp4',
  };
  final content = decryptContent ?? jsonEncode(payload);
  return MessageDBISAR(
    messageId: messageId,
    sender: 'sender',
    receiver: 'receiver',
    decryptContent: content,
    content: content,
    type: 'voice',
    createTime: 0,
  );
}

void main() {
  late io.Directory tempDir;
  late FakeVoiceCacheManager fakeCacheManager;

  setUp(() async {
    tempDir = await io.Directory.systemTemp.createTemp('voice_cache_test_');
    fakeCacheManager = FakeVoiceCacheManager(tempDir);
  });

  tearDown(() async {
    VoiceCacheManager.clearTestOverrides();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('VoiceCacheManager.getOrDownload', () {
    test('throws StateError when messageId is empty', () async {
      final msg = voiceMessage(messageId: '', url: 'https://example.com/a.m4a');
      expect(
        VoiceCacheManager.instance.getOrDownload(msg),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('messageId'),
        )),
      );
    });

    test('throws StateError when message has no url', () async {
      final msg = voiceMessage(
        messageId: 'ev1',
        url: '',
        decryptContent: jsonEncode({
          'contentType': 'voice',
          'durationSeconds': 5,
        }),
      );
      expect(
        VoiceCacheManager.instance.getOrDownload(msg),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('url'),
        )),
      );
    });

    test('throws when decryptContent has no url key', () async {
      final msg = voiceMessage(
        messageId: 'ev2',
        url: 'https://x.com/x.m4a',
        decryptContent: jsonEncode({'contentType': 'voice'}),
      );
      expect(
        VoiceCacheManager.instance.getOrDownload(msg),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('url'),
        )),
      );
    });
  });

  group('VoiceCacheManager.bindLocalFile', () {
    test('copies local file to cache then getOrDownload returns it', () async {
      VoiceCacheManager.setTestOverrides(
        cacheManager: fakeCacheManager,
      );
      final source = io.File('${tempDir.path}/source.m4a');
      await source.writeAsBytes([10, 20, 30]);

      await VoiceCacheManager.instance.bindLocalFile(
        messageId: 'ev_bind',
        url: 'https://example.com/any.m4a',
        localFilePath: source.path,
      );

      final msg = voiceMessage(
        messageId: 'ev_bind',
        url: 'https://example.com/any.m4a',
      );
      final file = await VoiceCacheManager.instance.getOrDownload(msg);
      expect(await file.exists(), isTrue);
      expect(await file.length(), 3);
      expect(await file.readAsBytes(), [10, 20, 30]);
    });

    test('no-op when messageId is empty', () async {
      final source = io.File('${tempDir.path}/empty_id.m4a');
      await source.writeAsBytes([1]);
      await VoiceCacheManager.instance.bindLocalFile(
        messageId: '',
        url: 'https://x.com/x.m4a',
        localFilePath: source.path,
      );
      // Should not throw; no file stored under empty key
    });

    test('no-op when source file does not exist', () async {
      VoiceCacheManager.setTestOverrides(cacheManager: fakeCacheManager);
      await VoiceCacheManager.instance.bindLocalFile(
        messageId: 'ev_nosource',
        url: 'https://example.com/x.m4a',
        localFilePath: '${tempDir.path}/nonexistent.m4a',
      );
      // Should not throw
      expect(
        await fakeCacheManager.getFileFromCache('ev_nosource'),
        isNull,
      );
    });
  });

  group('VoiceCacheManager.deleteCacheForMessage', () {
    test('removes cached file', () async {
      VoiceCacheManager.setTestOverrides(
        cacheManager: fakeCacheManager,
      );
      final source = io.File('${tempDir.path}/to_delete.m4a');
      await source.writeAsBytes([1, 2, 3]);
      await VoiceCacheManager.instance.bindLocalFile(
        messageId: 'ev_delete',
        url: 'https://example.com/d.m4a',
        localFilePath: source.path,
      );

      final msg = voiceMessage(
        messageId: 'ev_delete',
        url: 'https://example.com/d.m4a',
      );
      final file = await VoiceCacheManager.instance.getOrDownload(msg);
      expect(await file.exists(), isTrue);

      await VoiceCacheManager.instance.deleteCacheForMessage('ev_delete');
      expect(await file.exists(), isFalse);
      expect(fakeCacheManager.removeFileCalls, ['ev_delete']);
    });

    test('calls removeFile on underlying manager', () async {
      final fake = FakeVoiceCacheManager(tempDir);
      VoiceCacheManager.setTestOverrides(cacheManager: fake);

      await VoiceCacheManager.instance.deleteCacheForMessage('ev_xyz');

      expect(fake.removeFileCalls, ['ev_xyz']);
    });

    test('no-op when messageId is empty', () async {
      await VoiceCacheManager.instance.deleteCacheForMessage('');
      // should not throw
    });

    test('no-op when no cached file exists', () async {
      final fake = FakeVoiceCacheManager(tempDir);
      VoiceCacheManager.setTestOverrides(cacheManager: fake);

      await VoiceCacheManager.instance.deleteCacheForMessage('ev_never_cached');

      expect(fake.removeFileCalls, ['ev_never_cached']);
    });
  });

  group('VoiceCacheManager cache maintenance', () {
    test('deleteCacheForMessages removes each non-empty key', () async {
      final fake = FakeVoiceCacheManager(tempDir);
      VoiceCacheManager.setTestOverrides(cacheManager: fake);

      await VoiceCacheManager.instance
          .deleteCacheForMessages(['ev_a', '', 'ev_b']);

      expect(fake.removeFileCalls, ['ev_a', 'ev_b']);
    });

    test('clearAllCache calls emptyCache on underlying manager', () async {
      final fake = FakeVoiceCacheManager(tempDir);
      VoiceCacheManager.setTestOverrides(cacheManager: fake);

      await VoiceCacheManager.instance.clearAllCache();

      expect(fake.emptyCacheCalls, 1);
    });
  });
}
