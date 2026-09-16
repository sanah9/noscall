import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/core/call/contacts/prepared_direct_message.dart';
import 'package:noscall/voice_messages/voice_draft_store.dart';
import 'package:noscall/voice_messages/voice_send_controller.dart';

class MemoryDraftStore extends VoiceDraftStore {
  VoiceDraft? value = VoiceDraft(
    receiver: 'b' * 64,
    path: '/draft.m4a',
    durationSeconds: 4,
  );
  bool failSave = false;
  @override
  Future<VoiceDraft?> load() async => value;
  @override
  Future<void> save(VoiceDraft draft) async {
    if (failSave) throw const FileSystemException('disk full');
    value = draft;
  }

  @override
  Future<VoiceDraft> saveRecording(File file, int durationSeconds) async =>
      value = VoiceDraft(
        receiver: 'b' * 64,
        path: file.path,
        durationSeconds: durationSeconds,
      );
  @override
  Future<void> clear() async {
    value = null;
  }
}

class FakeVoiceBackend extends VoiceSendBackend {
  int uploads = 0;
  int preparations = 0;
  int finishes = 0;
  bool acknowledge = false;
  bool failFinish = false;
  Completer<bool>? pending;
  final published = <String>[];
  @override
  Future<Map<String, dynamic>> upload(
    VoiceDraft draft,
    void Function(double) progress,
  ) async {
    uploads++;
    progress(0.5);
    progress(1);
    return {'url': 'https://example.com/encrypted.bin'};
  }

  @override
  Future<PreparedDirectMessage> prepare(VoiceDraft draft) async {
    preparations++;
    return PreparedDirectMessage(
      messageId: 'id-$preparations',
      eventJson: '{}',
      createdAt: 10,
    );
  }

  @override
  Future<bool> publish(PreparedDirectMessage message) async {
    published.add(message.messageId);
    return pending == null ? acknowledge : await pending!.future;
  }

  @override
  Future<void> finish(VoiceDraft draft) async {
    finishes++;
    if (failFinish) throw const FileSystemException('disk full');
  }
}

void main() {
  test(
    'retry reuses uploaded audio and signed event after unknown delivery',
    () async {
      final store = MemoryDraftStore();
      final backend = FakeVoiceBackend();
      final first = VoiceSendController(store: store, backend: backend);
      await first.load();
      expect(await first.send(), isFalse);
      expect(first.progress, 1);
      expect(first.error, contains('not confirmed'));
      first.dispose();
      final resumed = VoiceSendController(store: store, backend: backend);
      await resumed.load();
      backend.acknowledge = true;
      expect(await resumed.send(), isTrue);
      expect(backend.uploads, 1);
      expect(backend.preparations, 1);
      expect(backend.published, ['id-1', 'id-1']);
      expect(store.value, isNull);
      resumed.dispose();
    },
  );

  test(
    'confirmed message only retries local saving after a disk failure',
    () async {
      final store = MemoryDraftStore();
      final backend = FakeVoiceBackend()
        ..acknowledge = true
        ..failFinish = true;
      final controller = VoiceSendController(store: store, backend: backend);
      await controller.load();
      expect(await controller.send(), isFalse);
      expect(controller.draft!.published, isTrue);
      backend.failFinish = false;
      expect(await controller.send(), isTrue);
      expect(backend.published, hasLength(1));
      expect(backend.finishes, 2);
      controller.dispose();
    },
  );

  test(
    'does not publish before durable save and prevents overlapping sends',
    () async {
      final store = MemoryDraftStore()..failSave = true;
      final backend = FakeVoiceBackend();
      final controller = VoiceSendController(store: store, backend: backend);
      await controller.load();
      expect(await controller.send(), isFalse);
      expect(backend.published, isEmpty);
      store.failSave = false;
      backend.pending = Completer<bool>();
      final sending = controller.send();
      await Future<void>.delayed(Duration.zero);
      expect(await controller.send(), isFalse);
      expect(backend.published, hasLength(1));
      backend.pending!.complete(true);
      expect(await sending, isTrue);
      controller.dispose();
    },
  );
}
