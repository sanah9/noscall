import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/call/contacts/contacts.dart';
import 'package:noscall/core/call/contacts/contacts_calling.dart';
import 'package:noscall/core/call/contacts/prepared_direct_message.dart';
import 'package:noscall/core/common/database/db_isar.dart';
import 'package:noscall/core/call/messages/model/message_db_isar.dart';
import 'package:noscall/core/call/messages/voice_attachment_cipher.dart';
import 'package:noscall/core/call/messages/voice_cache_manager.dart';

import 'voice_attachment_upload.dart';
import 'voice_draft_store.dart';

enum VoiceSendPhase { draft, uploading, preparing, sending, saving, sent }

abstract class VoiceSendBackend {
  Future<Map<String, dynamic>> upload(
    VoiceDraft draft,
    void Function(double) progress,
  );
  Future<PreparedDirectMessage> prepare(VoiceDraft draft);
  Future<bool> publish(PreparedDirectMessage message);
  Future<void> finish(VoiceDraft draft);
}

class DefaultVoiceSendBackend implements VoiceSendBackend {
  DefaultVoiceSendBackend(this.owner);
  final String owner;
  void _checkAccount() {
    if (Account.sharedInstance.currentPubkey != owner) {
      throw StateError('Account changed');
    }
  }

  @override
  Future<Map<String, dynamic>> upload(
    VoiceDraft draft,
    void Function(double) progress,
  ) async {
    _checkAccount();
    final attachment = await VoiceAttachmentUpload.upload(
      File(draft.path),
      onProgress: progress,
    );
    _checkAccount();
    return {
      'contentType': 'voice',
      'url': attachment.url,
      'encryption': attachment.encryption,
      'durationSeconds': draft.durationSeconds,
      'mimeType': 'audio/mp4',
    };
  }

  @override
  Future<PreparedDirectMessage> prepare(VoiceDraft draft) async {
    _checkAccount();
    final prepared = await Contacts.sharedInstance.prepareEncryptedDM(
      draft.receiver,
      jsonEncode(draft.content),
      replyToMessageId: draft.replyId,
    );
    _checkAccount();
    return prepared;
  }

  @override
  Future<bool> publish(PreparedDirectMessage message) {
    _checkAccount();
    return Contacts.sharedInstance.publishPreparedDM(message);
  }

  @override
  Future<void> finish(VoiceDraft draft) async {
    _checkAccount();
    final prepared = draft.prepared!;
    final content = jsonEncode(draft.content);
    await VoiceCacheManager.instance.bindLocalFile(
      messageId: prepared.messageId,
      url: draft.content!['url'] as String,
      localFilePath: draft.path,
      encrypted: true,
    );
    _checkAccount();
    final message = MessageDBISAR(
      messageId: prepared.messageId,
      sender: owner,
      receiver: draft.receiver,
      kind: 4,
      type: 'voice',
      content: content,
      decryptContent: content,
      replyId: draft.replyId,
      status: 1,
      createTime: prepared.createdAt,
      tags: jsonEncode([
        ['p', draft.receiver],
        if (draft.replyId.isNotEmpty) ['e', draft.replyId, '', 'reply'],
      ]),
    );
    final isar = DBISAR.sharedInstance.isar;
    await isar.writeTxn(() => isar.messageDBISARs.put(message));
    Contacts.sharedInstance.privateChatMessageCallBack?.call(message);
  }
}

class VoiceSendController extends ChangeNotifier {
  VoiceSendController({required this.store, required this.backend});
  final VoiceDraftStore store;
  final VoiceSendBackend backend;
  VoiceDraft? draft;
  VoiceSendPhase phase = VoiceSendPhase.draft;
  double progress = 0;
  bool busy = false;
  bool loadFailed = false;
  String? error;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    busy = true;
    _notify();
    try {
      draft = await store.load();
      loadFailed = false;
    } catch (_) {
      loadFailed = true;
      error = 'Draft could not be loaded. Discard it to start again.';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> saveRecording(File recording, int seconds) async {
    if (busy || loadFailed) throw StateError('Draft is not ready');
    busy = true;
    error = null;
    _notify();
    try {
      if (await recording.length() > VoiceAttachmentCipher.maxPlaintextBytes) {
        throw const FormatException('Recording too large');
      }
      draft = await store.saveRecording(recording, seconds);
      phase = VoiceSendPhase.draft;
    } catch (_) {
      error = 'Recording could not be saved (maximum 5 MB). Please retry.';
      rethrow;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> discard() async {
    if (busy) return;
    busy = true;
    _notify();
    try {
      await store.clear();
      draft = null;
      loadFailed = false;
      error = null;
      phase = VoiceSendPhase.draft;
    } catch (_) {
      error = 'Draft could not be removed. Please retry.';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> send() async {
    final current = draft;
    if (busy || current == null) return false;
    busy = true;
    error = null;
    try {
      if (current.content == null) {
        phase = VoiceSendPhase.uploading;
        progress = 0;
        _notify();
        current.content = await backend.upload(current, (value) {
          progress = value.clamp(0, 1);
          _notify();
        });
        await store.save(current);
      }
      if (current.prepared == null) {
        phase = VoiceSendPhase.preparing;
        _notify();
        current.prepared = await backend.prepare(current);
      }
      // Persist even on retries after a failed disk write; never publish first.
      await store.save(current);
      if (!current.published) {
        phase = VoiceSendPhase.sending;
        _notify();
        if (!await backend.publish(current.prepared!)) {
          throw const SocketException('No relay acknowledgement');
        }
        current.published = true;
        await store.save(current);
      }
      phase = VoiceSendPhase.saving;
      _notify();
      await backend.finish(current);
      await store.clear();
      phase = VoiceSendPhase.sent;
      draft = null;
      return true;
    } catch (_) {
      error = current.published
          ? 'Sent to a relay. Retry to finish saving on this device.'
          : 'Send not confirmed. Your draft is saved; retry uses the same message.';
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
