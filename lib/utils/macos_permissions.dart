import 'dart:io';
import 'package:flutter/services.dart';
import '../core/common/utils/log_utils.dart';

class MacOSPermissions {
  static const MethodChannel _channel = MethodChannel('sh.noscall.macos_permissions');

  static Future<bool> requestMicrophone() async {
    if (!Platform.isMacOS) {
      LogUtils.e(() => 'requestMicrophone called on non-macOS platform');
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('requestMicrophonePermission');
      return result ?? false;
    } catch (e) {
      LogUtils.e(() => 'Failed to request microphone permission: $e');
      return false;
    }
  }

  static Future<bool> requestCamera() async {
    if (!Platform.isMacOS) {
      LogUtils.e(() => 'requestCamera called on non-macOS platform');
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('requestCameraPermission');
      return result ?? false;
    } catch (e) {
      LogUtils.e(() => 'Failed to request camera permission: $e');
      return false;
    }
  }

  static Future<bool> checkMicrophone() async {
    if (!Platform.isMacOS) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('checkMicrophonePermission');
      return result ?? false;
    } catch (e) {
      LogUtils.e(() => 'Failed to check microphone permission: $e');
      return false;
    }
  }

  static Future<bool> checkCamera() async {
    if (!Platform.isMacOS) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('checkCameraPermission');
      return result ?? false;
    } catch (e) {
      LogUtils.e(() => 'Failed to check camera permission: $e');
      return false;
    }
  }
}
