import 'package:flutter/foundation.dart';

class LogUtils {
  static get showInfoLog => kDebugMode;

  static const int _maxLogLines = 500;
  static final List<String> _logBuffer = [];
  static final ValueNotifier<List<String>> logLinesNotifier =
      ValueNotifier<List<String>>([]);

  static List<String> get logLines => List.unmodifiable(_logBuffer);

  static void v(VoidCallback callback) {
    _print('VERBOSE', callback);
  }

  static void d(VoidCallback callback) {
    _print('DEBUG', callback);
  }

  static void i(VoidCallback callback) {
    _print('INFO', callback);
  }

  static void w(VoidCallback callback) {
    _print('WARN', callback);
  }

  static void e(VoidCallback callback) {
    _print('ERROR', callback);
  }

  static void error({String module = 'Call', required String className, required String funcName, required String message}) {
    e(() => '[Module - $module][$className - $funcName] $message');
  }

  static info({String module = 'Call', required String className, required String funcName, required String message}) {
    if (showInfoLog) i(() => '[${DateTime.now()}][Module - $module][$className - $funcName] $message');
  }

  static void _print(String level, VoidCallback fn) {
    try {
      final message = fn.call();
      final line = '[${DateTime.now()}] [$level] $message';
      if (kDebugMode) {
        print(line);
      }
      _logBuffer.add(line);
      if (_logBuffer.length > _maxLogLines) {
        _logBuffer.removeAt(0);
      }
      logLinesNotifier.value = List.from(_logBuffer);
    } catch (e) {
      if (kDebugMode) {
        print('$e');
      }
    }
  }
}

typedef VoidCallback = String Function();
