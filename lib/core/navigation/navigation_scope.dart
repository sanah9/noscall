/// How to perform a push: let system decide, tab-internal, or global (root).
enum NavigationScope {
  /// Use page preference if set, otherwise platform default (desktop: tab; mobile: root).
  automatic,

  /// Push onto the tab stack that **contains the caller** (desktop: [Navigator.of(context)]).
  /// On mobile, same as root.
  tabInternal,

  /// Push onto root/global stack (full-screen overlay).
  global,
}

/// Optional per-route preference when [NavigationScope.automatic] is used.
/// Keys are route paths (e.g. '/send-voice-message'). Absent = use default.
class NavigationScopeDefaults {
  NavigationScopeDefaults._();

  static const Map<String, NavigationScope> routePreference = {
    '/contact-select': NavigationScope.tabInternal,
    '/send-voice-message': NavigationScope.tabInternal,
    '/voice-message-detail': NavigationScope.tabInternal,
    '/user-detail': NavigationScope.tabInternal,
    '/profile-settings': NavigationScope.tabInternal,
    '/relay-management': NavigationScope.tabInternal,
    '/ice-server-management': NavigationScope.tabInternal,
    '/settings/theme': NavigationScope.tabInternal,
    '/call-payments/details': NavigationScope.tabInternal,
  };

  /// Resolve effective scope: callSite > pagePreference[route] > default (tabInternal on desktop).
  static NavigationScope resolve({
    required NavigationScope callSite,
    required String routePath,
    required bool isDesktop,
  }) {
    if (callSite != NavigationScope.automatic) return callSite;
    final preferred = routePreference[routePath];
    if (preferred != null) return preferred;
    return isDesktop ? NavigationScope.tabInternal : NavigationScope.global;
  }
}
