import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centralized status bar style configuration.
/// Change defaults here to affect the entire app.
class StatusBarStyle {
  StatusBarStyle._();

  /// Default style for normal pages (light background → dark icons, dark background → light icons).
  /// Used by AppBarTheme; modify here to change global default.
  static SystemUiOverlayStyle forBrightness(Brightness brightness) {
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          brightness == Brightness.light ? Brightness.dark : Brightness.light,
      statusBarBrightness:
          brightness == Brightness.light ? Brightness.light : Brightness.dark,
    );
  }

  /// Style for pages with dark header (e.g. gradient, primary color).
  /// Use light icons for visibility on dark background.
  static const SystemUiOverlayStyle forDarkHeader = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );
}
