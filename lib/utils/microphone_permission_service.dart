import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

import 'macos_permissions.dart';

/// Platform-agnostic microphone permission. Use for voice messages and recording.
/// macOS uses native MethodChannel (same as calls); other platforms use permission_handler.
class MicrophonePermissionService {
  MicrophonePermissionService._();

  static final MicrophonePermissionService instance = MicrophonePermissionService._();

  /// Request microphone access. Returns true if granted.
  Future<bool> request() async {
    if (Platform.isMacOS) {
      return MacOSPermissions.requestMicrophone();
    }
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    return false;
  }

  /// Check current status without requesting. Returns true if already granted.
  Future<bool> get isGranted async {
    if (Platform.isMacOS) {
      return MacOSPermissions.checkMicrophone();
    }
    final status = await Permission.microphone.status;
    return status.isGranted;
  }
}
