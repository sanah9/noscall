import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode options
enum ThemeModeOption {
  light,
  dark,
  system,
}

/// Service to manage app theme preferences
class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _themeModeKey = 'noscall_theme_mode';

  final ValueNotifier<ThemeModeOption> themeModeNotifier =
      ValueNotifier<ThemeModeOption>(ThemeModeOption.system);

  /// Initialize the theme service and load saved preference
  Future<void> initialize() async {
    try {
      final savedMode = await getThemeMode();
      themeModeNotifier.value = savedMode;
    } catch (e) {
      // If loading fails, use system default
      themeModeNotifier.value = ThemeModeOption.system;
    }
  }

  /// Get the saved theme mode preference
  Future<ThemeModeOption> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = prefs.getString(_themeModeKey);
      if (modeString == null) {
        return ThemeModeOption.system;
      }
      return ThemeModeOption.values.firstWhere(
        (mode) => mode.toString() == modeString,
        orElse: () => ThemeModeOption.system,
      );
    } catch (e) {
      return ThemeModeOption.system;
    }
  }

  /// Set and save the theme mode preference
  Future<void> setThemeMode(ThemeModeOption mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.toString());
      themeModeNotifier.value = mode;
    } catch (e) {
      // Silently fail - theme preference is not critical
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
  }
}
