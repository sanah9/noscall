import 'package:flutter/foundation.dart';

/// Simple logging utility for noscall-core
class LogUtils {
  static get showInfoLog => kDebugMode;

  static void v(VoidCallback callback) {
    // For now, just print to console
    // In production, you might want to use a proper logging framework
    print('[VERBOSE] ${callback()}');
  }

  static void d(VoidCallback callback) {
    print('[DEBUG] ${callback()}');
  }

  static void i(VoidCallback callback) {
    print('[INFO] ${callback()}');
  }

  static void w(VoidCallback callback) {
    print('[WARN] ${callback()}');
  }

  static void e(VoidCallback callback) {
    print('[ERROR] ${callback()}');
  }

  static void error({String module = 'Call', required String className, required String funcName, required String message}) {
    e(() => '[Module - $module][$className - $funcName] $message');
  }

  static info({String module = 'Call', required String className, required String funcName, required String message}) {
    if (showInfoLog) i(() => '[${DateTime.now()}][Module - $module][$className - $funcName] $message');
  }
}

typedef VoidCallback = String Function();
