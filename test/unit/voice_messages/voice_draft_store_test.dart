import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/core/call/contacts/prepared_direct_message.dart';
import 'package:noscall/voice_messages/voice_draft_store.dart';

void main() {
  test(
    'persists recording and send state across restarts with account isolation',
    () async {
      final root = await Directory.systemTemp.createTemp('voice_draft_test_');
      addTearDown(() => root.delete(recursive: true));
      final source = File('${root.path}/original.m4a');
      await source.writeAsBytes([1, 2, 3]);
      final owner = 'a' * 64;
      final receiver = 'b' * 64;
      final store = FileVoiceDraftStore(
        owner: owner,
        receiver: receiver,
        replyId: 'reply',
        root: root,
      );
      final draft = await store.saveRecording(source, 10);
      draft.content = {
        'url': 'https://example.com/audio.bin',
        'encryption': {'version': 1},
      };
      draft.prepared = const PreparedDirectMessage(
        messageId: 'id',
        eventJson: '{}',
        createdAt: 1,
      );
      draft.published = true;
      await store.save(draft);
      await source.delete();
      final resumed = await FileVoiceDraftStore(
        owner: owner,
        receiver: receiver,
        replyId: 'reply',
        root: root,
      ).load();
      expect(await File(resumed!.path).readAsBytes(), [1, 2, 3]);
      expect(resumed.prepared!.messageId, 'id');
      expect(resumed.published, isTrue);
      expect(resumed.content!['encryption'], {'version': 1});
      expect(await FileVoiceDraftStore.list(owner, root: root), hasLength(1));
      expect(await FileVoiceDraftStore.list('c' * 64, root: root), isEmpty);
      expect(
        await FileVoiceDraftStore(
          owner: owner,
          receiver: receiver,
          root: root,
        ).load(),
        isNull,
      );
      await store.clear();
      expect(await FileVoiceDraftStore.list(owner, root: root), isEmpty);
    },
  );
}
