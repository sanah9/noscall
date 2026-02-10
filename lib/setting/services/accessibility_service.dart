import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Text scale factor for accessibility. null = use system default.
class AccessibilityService {
  AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  static final AccessibilityService _instance =
      AccessibilityService._internal();

  static const String _keyTextScale = 'noscall_text_scale_factor';

  final ValueNotifier<double?> textScaleFactorNotifier =
      ValueNotifier<double?>(null);

  double? get textScaleFactor => textScaleFactorNotifier.value;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getDouble(_keyTextScale);
      textScaleFactorNotifier.value = v;
    } catch (e) {
      if (kDebugMode) {
        print('AccessibilityService init error: $e');
      }
    }
  }

  Future<void> setTextScaleFactor(double? value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value == null) {
        await prefs.remove(_keyTextScale);
      } else {
        await prefs.setDouble(_keyTextScale, value);
      }
      textScaleFactorNotifier.value = value;
    } catch (_) {}
  }

  void dispose() {
    textScaleFactorNotifier.dispose();
  }
}
