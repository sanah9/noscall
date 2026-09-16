import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:noscall/core/call/contacts/prepared_direct_message.dart';
import 'package:path_provider/path_provider.dart';

class VoiceDraft {
  VoiceDraft({
    required this.receiver,
    required this.path,
    required this.durationSeconds,
    this.replyId = '',
    this.content,
    this.prepared,
    this.published = false,
  });
  final String receiver;
  final String replyId;
  final String path;
  final int durationSeconds;
  Map<String, dynamic>? content;
  PreparedDirectMessage? prepared;
  bool published;

  Map<String, dynamic> toJson() => {
    'receiver': receiver,
    'replyId': replyId,
    'durationSeconds': durationSeconds,
    'content': content,
    'prepared': prepared?.toJson(),
    'published': published,
  };
}

abstract class VoiceDraftStore {
  Future<VoiceDraft?> load();
  Future<VoiceDraft> saveRecording(File file, int durationSeconds);
  Future<void> save(VoiceDraft draft);
  Future<void> clear();
}

class FileVoiceDraftStore implements VoiceDraftStore {
  FileVoiceDraftStore({
    required this.owner,
    required this.receiver,
    this.replyId = '',
    this.root,
  }) {
    if (![
      owner,
      receiver,
    ].every((key) => RegExp(r'^[0-9a-f]{64}$').hasMatch(key))) {
      throw ArgumentError('A valid sender and recipient are required');
    }
  }
  final String owner;
  final String receiver;
  final String replyId;
  final Directory? root;
  String get _id =>
      sha256.convert(utf8.encode('$receiver:$replyId')).toString();
  Future<Directory> _directory() async {
    final base = root ?? await getApplicationSupportDirectory();
    return Directory('${base.path}/voice_drafts/$owner/$_id');
  }

  @override
  Future<VoiceDraft?> load() async {
    final directory = await _directory();
    final metadata = File('${directory.path}/draft.json');
    if (!await metadata.exists()) return null;
    final map =
        jsonDecode(await metadata.readAsString()) as Map<String, dynamic>;
    if (map['receiver'] != receiver || map['replyId'] != replyId) {
      throw const FormatException('Invalid draft');
    }
    final audio = File('${directory.path}/recording.m4a');
    if (!await audio.exists()) {
      throw const FormatException('Draft audio is missing');
    }
    return VoiceDraft(
      receiver: receiver,
      replyId: replyId,
      path: audio.path,
      durationSeconds: map['durationSeconds'] as int,
      content: map['content'] as Map<String, dynamic>?,
      prepared: map['prepared'] == null
          ? null
          : PreparedDirectMessage.fromJson(
              map['prepared'] as Map<String, dynamic>,
            ),
      published: map['published'] == true,
    );
  }

  @override
  Future<VoiceDraft> saveRecording(File file, int durationSeconds) async {
    if (durationSeconds <= 0 || durationSeconds > 120) {
      throw const FormatException('Invalid duration');
    }
    final directory = await _directory();
    await directory.create(recursive: true);
    final audio = File('${directory.path}/recording.m4a');
    if (file.path != audio.path) await file.copy(audio.path);
    final draft = VoiceDraft(
      receiver: receiver,
      replyId: replyId,
      path: audio.path,
      durationSeconds: durationSeconds,
    );
    await save(draft);
    return draft;
  }

  @override
  Future<void> save(VoiceDraft draft) async {
    final directory = await _directory();
    await directory.create(recursive: true);
    final temporary = File('${directory.path}/draft.tmp');
    await temporary.writeAsString(jsonEncode(draft.toJson()), flush: true);
    await temporary.rename('${directory.path}/draft.json');
  }

  @override
  Future<void> clear() async {
    final directory = await _directory();
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  static Future<List<VoiceDraft>> list(String owner, {Directory? root}) async {
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(owner)) return [];
    final base = root ?? await getApplicationSupportDirectory();
    final account = Directory('${base.path}/voice_drafts/$owner');
    if (!await account.exists()) return [];
    final drafts = <VoiceDraft>[];
    await for (final entry in account.list(followLinks: false)) {
      if (entry is! Directory) continue;
      try {
        final metadata = File('${entry.path}/draft.json');
        final data =
            jsonDecode(await metadata.readAsString()) as Map<String, dynamic>;
        final store = FileVoiceDraftStore(
          owner: owner,
          receiver: data['receiver'] as String,
          replyId: data['replyId'] as String,
          root: base,
        );
        final draft = await store.load();
        if (draft != null) drafts.add(draft);
      } catch (_) {
        // An interrupted recording cannot prevent other drafts from loading.
      }
    }
    return drafts;
  }
}
