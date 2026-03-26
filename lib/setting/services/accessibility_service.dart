import 'package:flutter/foundation.dart';
import 'package:noscall/core/common/storage/preferences_store.dart';
import 'package:noscall/core/common/utils/log_utils.dart';

/// Text scale factor for accessibility. null = use system default.
class AccessibilityService {
  AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  static final AccessibilityService _instance =
      AccessibilityService._internal();

  static const String _keyTextScale = 'noscall_text_scale_factor';
  final PreferencesStore _prefs = PreferencesStore.shared;

  final ValueNotifier<double?> textScaleFactorNotifier =
      ValueNotifier<double?>(null);

  double? get textScaleFactor => textScaleFactorNotifier.value;

  Future<void> initialize() async {
    textScaleFactorNotifier.value = await _prefs.getDouble(_keyTextScale);
  }

  Future<void> setTextScaleFactor(double? value) async {
    final ok = value == null
        ? await _prefs.remove(_keyTextScale)
        : await _prefs.setDouble(_keyTextScale, value);
    if (ok) {
      textScaleFactorNotifier.value = value;
    } else {
      LogUtils.w(() => 'AccessibilityService.setTextScaleFactor failed');
    }
  }

  void dispose() {
    textScaleFactorNotifier.dispose();
  }
}
