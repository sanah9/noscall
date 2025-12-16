import 'package:flutter/material.dart';
import '../contacts/user_detail_page.dart';
import '../profile/profile_settings_page.dart';
import 'desktop_recent_calls_page.dart';
import 'desktop_contacts_page.dart';
import 'desktop_settings_page.dart';

class DesktopNavigatorProvider extends InheritedWidget {
  final DesktopNavigatorState navigatorState;

  const DesktopNavigatorProvider({
    super.key,
    required this.navigatorState,
    required super.child,
  });

  static DesktopNavigatorState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DesktopNavigatorProvider>()?.navigatorState;
  }

  @override
  bool updateShouldNotify(DesktopNavigatorProvider oldWidget) {
    return navigatorState != oldWidget.navigatorState;
  }
}

class DesktopNavigator extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onNavigationChanged;

  const DesktopNavigator({
    super.key,
    required this.selectedIndex,
    required this.onNavigationChanged,
  });

  @override
  State<DesktopNavigator> createState() => DesktopNavigatorState();
}

class DesktopNavigatorState extends State<DesktopNavigator> {
  final List<GlobalKey<NavigatorState>> _navigatorKeyObjects = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  void navigateToContactDetail(String pubkey) {
    final currentNavigator = _navigatorKeyObjects[widget.selectedIndex].currentState;
    currentNavigator?.push(
      MaterialPageRoute(
        builder: (context) => UserDetailPage(
          pubkey: pubkey,
          callHistory: null,
        ),
      ),
    );
  }

  void navigateToProfileSettings() {
    final currentNavigator = _navigatorKeyObjects[2].currentState;
    currentNavigator?.push(
      MaterialPageRoute(
        builder: (context) => const ProfileSettingsPage(),
      ),
    );
  }

  bool canPop() {
    final currentNavigator = _navigatorKeyObjects[widget.selectedIndex].currentState;
    return currentNavigator?.canPop() ?? false;
  }

  void pop() {
    final currentNavigator = _navigatorKeyObjects[widget.selectedIndex].currentState;
    if (currentNavigator?.canPop() ?? false) {
      currentNavigator?.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesktopNavigatorProvider(
      navigatorState: this,
      child: IndexedStack(
        index: widget.selectedIndex,
        children: [
          Navigator(
            key: _navigatorKeyObjects[0],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const DesktopRecentCallsPage(),
              );
            },
          ),
          Navigator(
            key: _navigatorKeyObjects[1],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const DesktopContactsPage(),
              );
            },
          ),
          Navigator(
            key: _navigatorKeyObjects[2],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const DesktopSettingsPage(),
              );
            },
          ),
        ],
      ),
    );
  }
}