import 'package:flutter/foundation.dart';

class LogUtils {
  static get showInfoLog => kDebugMode;

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
    if (kDebugMode) {
      try {
        final message = fn.call();
        print('[$level] $message');
      } catch (e) {
        print('$e');
      }
    }
  }
}

typedef VoidCallback = String Function();
