import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import '../core/common/utils/log_utils.dart';

class PipManager {
  static const MethodChannel _channel = MethodChannel('sh.noscall.pip');
  static const EventChannel _eventChannel = EventChannel('sh.noscall.pip/events');
  
  static final StreamController<bool> _pipStateController =
    StreamController<bool>.broadcast();

  static Stream<bool> get pipStateStream => _pipStateController.stream;

  static bool _isPipMode = false;
  static bool get isPipMode => _isPipMode;

  static bool _isInitialized = false;
  static StreamSubscription<dynamic>? _eventSubscription;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (Platform.isAndroid) {
        _channel.setMethodCallHandler(_handleMethodCall);
      } else if (Platform.isIOS) {
        // iOS uses EventChannel for PiP events
        _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
          _handleIOSPiPEvent,
          onError: (error) {
            LogUtils.e(() => 'PiP event stream error: $error');
          },
        );
      }
      
      _isInitialized = true;
      LogUtils.i(() => 'PipManager initialized for ${Platform.operatingSystem}');
    } catch (e) {
      LogUtils.e(() => 'Failed to initialize PipManager: $e');
    }
  }

  static void _handleIOSPiPEvent(dynamic event) {
    if (event is Map) {
      final eventType = event['event'] as String?;
      final data = event['data'];
      
      LogUtils.i(() => 'PiP event: $eventType - $data');
      
      switch (eventType) {
        case 'started':
          _isPipMode = true;
          _pipStateController.add(true);
          break;
        case 'stopped':
          _isPipMode = false;
          _pipStateController.add(false);
          break;
        case 'willStart':
        case 'willStop':
          // These are informational events
          break;
        case 'failed':
          final errorMessage = data is String ? data : 'Unknown error';
          LogUtils.e(() => 'PiP failed: $errorMessage');
          _isPipMode = false;
          _pipStateController.add(false);
          break;
      }
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

  /// Check if PiP is available (iOS) or supported (Android)
  static Future<bool> isPipSupported() async {
    try {
      if (Platform.isIOS) {
        final bool? available = await _channel.invokeMethod('isPipAvailable');
        return available ?? false;
      } else if (Platform.isAndroid) {
        final bool? supported = await _channel.invokeMethod('isPipSupported');
        return supported ?? false;
      }
      return false;
    } catch (e) {
      LogUtils.e(() => 'Failed to check PiP support: $e');
      return false;
    }
  }

  /// Start Picture-in-Picture
  /// For iOS: requires trackId parameter
  /// For Android: no parameters needed
  static Future<bool> startPiP({String? trackId}) async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('enablePip');
        LogUtils.i(() => 'PiP enabled (Android)');
        return true;
      } else if (Platform.isIOS) {
        if (trackId == null || trackId.isEmpty) {
          LogUtils.e(() => 'trackId is required for iOS PiP');
          return false;
        }
        await _channel.invokeMethod('startPip', {'trackId': trackId});
        LogUtils.i(() => 'PiP start requested (iOS)');
        return true;
      }
      return false;
    } catch (e) {
      LogUtils.e(() => 'Failed to start PiP: $e');
      return false;
    }
  }

  /// Stop Picture-in-Picture
  static Future<void> disablePip() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('disablePip');
        _isPipMode = false;
        LogUtils.i(() => 'PiP disabled (Android)');
      } else if (Platform.isIOS) {
        await _channel.invokeMethod('stopPip');
        LogUtils.i(() => 'PiP stopped (iOS)');
      }
    } catch (e) {
      LogUtils.e(() => 'Failed to disable PiP: $e');
    }
  }

  /// Enter PiP mode (Android only - legacy method)
  static Future<bool> enterPip() async {
    if (Platform.isAndroid) {
      return await startPiP();
    }
    return false;
  }

  /// Enable PiP (alias for startPiP for backward compatibility)
  static Future<void> enablePip() async {
    await startPiP();
  }

  static void dispose() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _pipStateController.close();
    _isInitialized = false;
  }
}