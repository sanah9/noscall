import 'package:flutter/material.dart';

/// Applies a **light** [ColorScheme] (from the parent primary seed) to [child]
/// and descendants, while the app may be in dark mode—use for any widgets that
/// sit on a fixed light surface (e.g. white cards), not only text fields.
Widget authLightSchemeTheme(BuildContext context, {required Widget child}) {
  final parent = Theme.of(context);
  final lightScheme = ColorScheme.fromSeed(
    seedColor: parent.colorScheme.primary,
    brightness: Brightness.light,
  );
  return Theme(
    data: ThemeData(
      useMaterial3: parent.useMaterial3,
      colorScheme: lightScheme,
    ),
    child: child,
  );
}
