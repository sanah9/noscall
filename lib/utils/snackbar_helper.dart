import 'package:flutter/material.dart';

/// SnackBar display type: info, warning, error.
enum SnackBarType {
  /// Info (general message, success, etc.)
  info,

  /// Warning.
  warning,

  /// Error.
  error,
}

/// Unified SnackBar helper. Callers pass [message] and [SnackBarType]; styling is handled here.
class AppSnackBar {
  AppSnackBar._();

  /// Shows a SnackBar. [message] is the text; [type] (info/warning/error) controls background and semantics.
  /// Uses [ScaffoldMessenger.maybeOf] and does nothing if context is invalid or no Scaffold, to avoid exceptions.
  static void show(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration? duration,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final backgroundColor = _backgroundColor(colorScheme, type);
    final contentColor = _contentColor(colorScheme, type);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(color: contentColor),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  static Color _backgroundColor(ColorScheme scheme, SnackBarType type) {
    switch (type) {
      case SnackBarType.info:
        return scheme.inverseSurface;
      case SnackBarType.warning:
        return scheme.tertiaryContainer;
      case SnackBarType.error:
        return scheme.errorContainer;
    }
  }

  static Color _contentColor(ColorScheme scheme, SnackBarType type) {
    switch (type) {
      case SnackBarType.info:
        return scheme.onInverseSurface;
      case SnackBarType.warning:
        return scheme.onTertiaryContainer;
      case SnackBarType.error:
        return scheme.onErrorContainer;
    }
  }

  /// Convenience: show info SnackBar.
  static void info(BuildContext context, String message, {Duration? duration}) {
    show(context, message, type: SnackBarType.info, duration: duration);
  }

  /// Convenience: show warning SnackBar.
  static void warning(BuildContext context, String message, {Duration? duration}) {
    show(context, message, type: SnackBarType.warning, duration: duration);
  }

  /// Convenience: show error SnackBar.
  static void error(BuildContext context, String message, {Duration? duration}) {
    show(context, message, type: SnackBarType.error, duration: duration);
  }
}
