import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/voice_messages/send_voice_message_page.dart';
import 'package:noscall/voice_messages/voice_recording_device.dart';
import 'package:noscall/voice_messages/voice_send_controller.dart';

import '../../unit/voice_messages/voice_send_controller_test.dart'
    show MemoryDraftStore, FakeVoiceBackend;

class FakeRecorder extends VoiceRecordingDevice {
  bool permission = false;
  File? recording;
  @override
  Future<bool> requestPermission() async => permission;
  @override
  Future<void> start() async {}
  @override
  Future<File?> stop() async => recording;
  @override
  Future<void> dispose() async {}
}

void main() {
  testWidgets('stopping saves a draft without uploading or sending', (
    tester,
  ) async {
    final directory = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('voice-widget-'),
    ))!;
    final file = (await tester.runAsync(
      () => File('${directory.path}/recording.m4a').writeAsBytes([1, 2]),
    ))!;
    addTearDown(() => directory.delete(recursive: true));
    final store = MemoryDraftStore()..value = null;
    final backend = FakeVoiceBackend();
    final controller = VoiceSendController(store: store, backend: backend);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SendVoiceMessagePage(
          receiverPubkey: 'b' * 64,
          controller: controller,
          recorder: FakeRecorder()
            ..permission = true
            ..recording = file,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record'));
    await tester.pump();
    await tester.tap(find.text('Stop recording'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pumpAndSettle();
    expect(find.text('Send'), findsOneWidget);
    expect(store.value, isNotNull);
    expect(backend.uploads, 0);
    expect(backend.published, isEmpty);
  });

  testWidgets(
    'restored draft offers preview and explicit send without sending automatically',
    (tester) async {
      final backend = FakeVoiceBackend();
      final controller = VoiceSendController(
        store: MemoryDraftStore(),
        backend: backend,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: SendVoiceMessagePage(
            receiverPubkey: 'b' * 64,
            controller: controller,
            recorder: FakeRecorder(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Preview recording'), findsOneWidget);
      expect(find.text('Draft saved on this device'), findsOneWidget);
      expect(backend.published, isEmpty);
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(find.text('Retry send'), findsOneWidget);
      expect(backend.published, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('permission denial keeps recorder stopped and offers settings', (
    tester,
  ) async {
    final store = MemoryDraftStore()..value = null;
    final controller = VoiceSendController(
      store: store,
      backend: FakeVoiceBackend(),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SendVoiceMessagePage(
          receiverPubkey: 'b' * 64,
          controller: controller,
          recorder: FakeRecorder(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record'));
    await tester.pumpAndSettle();
    expect(find.text('Microphone settings'), findsOneWidget);
    expect(find.text('Stop recording'), findsNothing);
  });
}
