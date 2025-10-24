import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:noscall/core/common/utils/log_utils.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';
import '../core/account/account.dart';
import 'hash_util.dart';

class FileUploadManager {
  static const String _serverUrl = 'https://blossom.band';
  static const int _maxFileSize = 5 * 1024 * 1024;
  static var dio = Dio();

  static Future<String?> uploadFile(File file, {
    Function(double progress)? onProgress,
  }) async {
    try {
      final fileSize = await file.length();
      if (fileSize > _maxFileSize) {
        throw Exception('File size exceeds 50 MiB limit');
      }

      Uint8List bytes = file.readAsBytesSync();
      if (bytes.isEmpty) {
        return null;
      }

      final fileName = file.path.split('/').lastOrNull ?? const Uuid().v4();

      String payload = HashUtil.sha256Bytes(bytes);

      // Prepare headers
      Map<String, String> headers = {};
      String? mimeType = lookupMimeType(fileName);
      if (mimeType != null && mimeType.isNotEmpty) {
        headers['Content-Type'] = mimeType;
      } else {
        headers['Content-Type'] = 'application/octet-stream';
      }

      List<List<String>> tags = [];
      tags.add(['t', 'upload']);
      tags.add([
        'expiration',
        ((DateTime.now().millisecondsSinceEpoch ~/ 1000) + 60 * 10).toString()
      ]);
      tags.add(['size', '$fileSize']);
      tags.add(['x', payload]);

      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final eventData = {
        'pubkey': Account.sharedInstance.currentPubkey,
        'created_at': currentTime,
        'kind': 24242,
        'tags': tags,
        'content': 'Upload $fileName'
      };

      final signedEvent = await Account.sharedInstance.signEvent(eventData);

      headers['Authorization'] =
      'Nostr ${base64Url.encode(utf8.encode(jsonEncode(signedEvent)))}';

      // Upload file
      var uploadApiPath = '$_serverUrl/upload';

      var response = await dio.put(
        uploadApiPath,
        data: bytes,
        options: Options(
          headers: headers,
          validateStatus: (status) {
            return true;
          },
        ),
        onSendProgress: (count, total) {
          onProgress?.call(count / total);
        },
      );

      var body = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (body is Map<String, dynamic>) {
          if (body['url'] != null) {
            return body['url'];
          } else if (body['sha256'] != null || body['hash'] != null) {
            final fileHash = body['sha256'] ?? body['hash'];
            final extension = fileName.split('.').lastOrNull ?? 'bin';
            return '$_serverUrl/$fileHash.$extension';
          }
        }
      }

      throw Exception('Upload failed: ${response.statusCode} - ${response.data}');
    } catch (e) {
      LogUtils.e(() => 'FileUploadManager.upload upload exception: $e');
      return null;
    }
  }

  static Future<String?> uploadImage(File imageFile, {Function(double progress)? onProgress}) async {
    final url = await uploadFile(imageFile, onProgress: onProgress);
    if (url != null && url.isNotEmpty) {
      Future.microtask(() async {
        CachedNetworkImageProvider.defaultCacheManager.putFile(
          url,
          await imageFile.readAsBytes(),
        );
      });
    }
    return url;
  }

  static bool isSupportedFileType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    const supportedTypes = [
      'jpg', 'jpeg', 'png', 'webp', 'gif', 'mp4', 'mov',
      'wav', 'mp3', 'flac', 'pdf', 'svg', 'zip'
    ];
    return supportedTypes.contains(extension);
  }

  static String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static Future<Event> _createAuthEvent() async {
    List<List<String>> tags = [];
    tags.add(['u', _serverUrl]);
    tags.add(['method', 'DELETE']);
    tags.add(['t', 'upload']);
    tags.add([
      'expiration',
      ((DateTime.now().millisecondsSinceEpoch ~/ 1000) + 60 * 10).toString()
    ]);

    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final eventData = {
      'pubkey': Account.sharedInstance.currentPubkey,
      'created_at': currentTime,
      'kind': 24242,
      'tags': tags,
      'content': 'Upload authentication for blossom.band'
    };

    final signedEvent = await Account.sharedInstance.signEvent(eventData);
    return Event.fromJson(signedEvent);
  }

  static Future<bool> deleteFile(String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isEmpty) return false;

      final fileName = pathSegments.last;
      final fileHash = fileName.split('.').first;

      final authEvent = await _createAuthEvent();

      final deleteUrl = '$_serverUrl/$fileHash';
      final response = await dio.delete(
        deleteUrl,
        options: Options(
          headers: {
            'Authorization': 'Nostr ${base64Url.encode(utf8.encode(jsonEncode(authEvent.toJson())))}',
          },
          validateStatus: (status) => true,
        ),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      LogUtils.e(() => 'FileUploadManager.deleteFile error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getFileMetadata(String fileUrl) async {
    try {
      final response = await dio.head(
        fileUrl,
        options: Options(
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200) {
        return {
          'content_length': response.headers.value('content-length'),
          'content_type': response.headers.value('content-type'),
          'last_modified': response.headers.value('last-modified'),
        };
      }
      return null;
    } catch (e) {
      LogUtils.e(() => 'FileUploadManager.getFileMetadata error: $e');
      return null;
    }
  }

  static Future<bool> checkServerStatus() async {
    try {
      final response = await dio.get(
        _serverUrl,
        options: Options(
          validateStatus: (status) => true,
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}