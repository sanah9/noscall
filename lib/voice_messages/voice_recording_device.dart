import 'dart:io';

import 'package:noscall/utils/microphone_permission_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

abstract class VoiceRecordingDevice {
  Future<bool> requestPermission();
  Future<void> start();
  Future<File?> stop();
  Future<void> dispose();
}

class DefaultVoiceRecordingDevice implements VoiceRecordingDevice {
  final _recorder = AudioRecorder();
  @override
  Future<bool> requestPermission() =>
      MicrophonePermissionService.instance.request();
  @override
  Future<void> start() async {
    final dir = await getTemporaryDirectory();
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: '${dir.path}/voice_${const Uuid().v4()}.m4a',
    );
  }

  @override
  Future<File?> stop() async {
    final path = await _recorder.stop();
    return path == null ? null : File(path);
  }

  @override
  Future<void> dispose() => _recorder.dispose();
}
