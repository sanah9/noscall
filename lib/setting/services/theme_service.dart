import 'package:flutter/material.dart';
import 'package:noscall/core/common/storage/preferences_store.dart';
import 'package:noscall/core/common/utils/log_utils.dart';

/// Theme mode options
enum ThemeModeOption {
  light,
  dark,
  system,
}

/// Default seed color (purple)
const int kDefaultSeedColorValue = 0xFF3937A3;

/// Preset accent colors for theme customization
const List<int> kPresetSeedColors = [
  0xFF3937A3, // purple (default)
  0xFF1976D2, // blue
  0xFF388E3C, // green
  0xFFF57C00, // orange
  0xFFD32F2F, // red
  0xFF7B1FA2, // deep purple
];

/// Service to manage app theme preferences
class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _themeModeKey = 'noscall_theme_mode';
  static const String _seedColorKey = 'noscall_seed_color';
  final PreferencesStore _prefs = PreferencesStore.shared;

  final ValueNotifier<ThemeModeOption> themeModeNotifier =
      ValueNotifier<ThemeModeOption>(ThemeModeOption.system);
  final ValueNotifier<int> seedColorValueNotifier =
      ValueNotifier<int>(kDefaultSeedColorValue);

  /// Initialize the theme service and load saved preference
  Future<void> initialize() async {
    try {
      final savedMode = await getThemeMode();
      themeModeNotifier.value = savedMode;
      final savedColor = await getSeedColorValue();
      seedColorValueNotifier.value = savedColor;
    } catch (e, stack) {
      LogUtils.e(() => 'ThemeService.initialize failed: $e, $stack');
      themeModeNotifier.value = ThemeModeOption.system;
      seedColorValueNotifier.value = kDefaultSeedColorValue;
    }
  }

  /// Get the saved theme mode preference
  Future<ThemeModeOption> getThemeMode() async {
    try {
      final modeString = await _prefs.getString(_themeModeKey);
      if (modeString == null) {
        return ThemeModeOption.system;
      }
      return ThemeModeOption.values.firstWhere(
        (mode) => mode.toString() == modeString,
        orElse: () => ThemeModeOption.system,
      );
    } catch (e, stack) {
      LogUtils.e(() => 'ThemeService.getThemeMode failed: $e, $stack');
      return ThemeModeOption.system;
    }
  }

  /// Set and save the theme mode preference
  Future<void> setThemeMode(ThemeModeOption mode) async {
    final ok = await _prefs.setString(_themeModeKey, mode.toString());
    if (ok) {
      themeModeNotifier.value = mode;
    } else {
      LogUtils.w(() => 'ThemeService.setThemeMode failed to persist');
    }
  }

  /// Get saved seed color value (ARGB int)
  Future<int> getSeedColorValue() async {
    final v = await _prefs.getInt(_seedColorKey);
    return v ?? kDefaultSeedColorValue;
  }

  /// Set and save seed color (ARGB int)
  Future<void> setSeedColorValue(int value) async {
    final ok = await _prefs.setInt(_seedColorKey, value);
    if (ok) {
      seedColorValueNotifier.value = value;
    } else {
      LogUtils.w(() => 'ThemeService.setSeedColorValue failed to persist');
    }
  }

  /// Convert ThemeModeOption to Flutter's ThemeMode
  ThemeMode toFlutterThemeMode(ThemeModeOption option) {
    switch (option) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
        return ThemeMode.system;
    }
  }

  /// Get current Flutter ThemeMode
  ThemeMode get currentThemeMode {
    return toFlutterThemeMode(themeModeNotifier.value);
  }

  /// Dispose resources
  void dispose() {
    themeModeNotifier.dispose();
    seedColorValueNotifier.dispose();
  }
}
