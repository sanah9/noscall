import 'dart:io';
import 'package:flutter/services.dart';

class NativeMethodChannel {
  static const MethodChannel _channel = MethodChannel('com.noscall.native_methods');

  static Future<void> useManualAudio() async {
    if (Platform.isIOS) {
      try {
        await _channel.invokeMethod('useManualAudio');
      } on PlatformException catch (e) {
        throw NativeMethodException(
          code: e.code,
          message: e.message ?? 'Unknown error',
          details: e.details,
        );
      }
    }
  }

  static Future<void> audioSessionDidActivate() async {
    if (Platform.isIOS) {
      try {
        await _channel.invokeMethod('audioSessionDidActivate');
      } on PlatformException catch (e) {
        throw NativeMethodException(
          code: e.code,
          message: e.message ?? 'Unknown error',
          details: e.details,
        );
      }
    }
  }

  static Future<void> audioSessionDidDeactivate() async {
    if (Platform.isIOS) {
      try {
        await _channel.invokeMethod('audioSessionDidDeactivate');
      } on PlatformException catch (e) {
        throw NativeMethodException(
          code: e.code,
          message: e.message ?? 'Unknown error',
          details: e.details,
        );
      }
    }
  }
}

class NativeMethodException implements Exception {
  final String code;
  final String message;
  final dynamic details;

  const NativeMethodException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() {
    return 'NativeMethodException: $code - $message';
  }
}