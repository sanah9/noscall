import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import '../core/common/utils/log_utils.dart';

class PipManager {
  static const MethodChannel _channel = MethodChannel('sh.noscall.pip');
  static final StreamController<bool> _pipStateController =
  StreamController<bool>.broadcast();

  static Stream<bool> get pipStateStream => _pipStateController.stream;

  static bool _isPipMode = false;
  static bool get isPipMode => _isPipMode;

  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    if (!Platform.isAndroid) {
      LogUtils.i(() => 'PiP is only supported on Android');
      return;
    }

    try {
      _channel.setMethodCallHandler(_handleMethodCall);
      _isInitialized = true;
      LogUtils.i(() => 'PipManager initialized');
    } catch (e) {
      LogUtils.e(() => 'Failed to initialize PipManager: $e');
    }
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPipModeChanged':
        _isPipMode = call.arguments as bool;
        _pipStateController.add(_isPipMode);
        LogUtils.i(() => 'PiP mode changed: $_isPipMode');
        break;
      default:
        LogUtils.w(() => 'Unknown method: ${call.method}');
    }
  }

  static Future<bool> isPipSupported() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final bool? supported = await _channel.invokeMethod('isPipSupported');
      return supported ?? false;
    } catch (e) {
      LogUtils.e(() => 'Failed to check PiP support: $e');
      return false;
    }
  }

  static Future<void> enablePip() async {
    if (!Platform.isAndroid) {
      LogUtils.w(() => 'PiP is only supported on Android');
      return;
    }

    try {
      await _channel.invokeMethod('enablePip');
      LogUtils.i(() => 'PiP enabled');
    } catch (e) {
      LogUtils.e(() => 'Failed to enable PiP: $e');
    }
  }

  static Future<void> disablePip() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await _channel.invokeMethod('disablePip');
      _isPipMode = false;
      LogUtils.i(() => 'PiP disabled');
    } catch (e) {
      LogUtils.e(() => 'Failed to disable PiP: $e');
    }
  }

  static Future<bool> enterPip() async {
    if (!Platform.isAndroid) {
      LogUtils.w(() => 'PiP is only supported on Android');
      return false;
    }

    try {
      final bool? success = await _channel.invokeMethod('enterPip');
      return success ?? false;
    } catch (e) {
      LogUtils.e(() => 'Failed to enter PiP: $e');
      return false;
    }
  }

  static void dispose() {
    _pipStateController.close();
    _isInitialized = false;
  }
}