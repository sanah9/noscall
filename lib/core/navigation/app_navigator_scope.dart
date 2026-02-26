import 'package:flutter/material.dart';

import 'app_navigator.dart';

/// Provides [AppNavigator] to the subtree. Mount one in the shell (e.g. [HomePage]
/// for mobile, [DesktopNavigator] for desktop) so all pages use the same API
/// regardless of platform.
class AppNavigatorScope extends InheritedWidget {
  const AppNavigatorScope({
    super.key,
    required this.navigator,
    required super.child,
  });

  final AppNavigator navigator;

  static AppNavigator? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppNavigatorScope>()
        ?.navigator;
  }

  /// Returns the [AppNavigator] for this context. Throws if not found (unexpected;
  /// call only from widgets under a shell that provides [AppNavigatorScope]).
  static AppNavigator requireOf(BuildContext context) {
    final nav = of(context);
    if (nav == null) {
      throw FlutterError(
        'AppNavigatorScope.requireOf(context) called but no AppNavigatorScope '
        'found in context. Ensure the widget is built under the app shell '
        '(e.g. HomePage or DesktopNavigator) that provides AppNavigatorScope.',
      );
    }
    return nav;
  }

  static AppNavigator? maybeOf(BuildContext context) => of(context);

  @override
  bool updateShouldNotify(AppNavigatorScope oldWidget) {
    return navigator != oldWidget.navigator;
  }
}
