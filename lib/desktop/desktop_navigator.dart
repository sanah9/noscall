import 'package:flutter/material.dart';
import 'package:noscall/core/navigation/app_navigator_scope.dart';
import 'package:noscall/voice_messages/voice_messages_page.dart';
import 'desktop_recent_calls_page.dart';
import 'desktop_contacts_page.dart';
import 'desktop_group_list_page.dart';
import 'desktop_settings_page.dart';
import 'desktop_tab_app_navigator.dart';

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
  static const int _tabRecent = 0;
  static const int _tabContacts = 1;
  static const int _tabGroups = 2;
  static const int _tabVoice = 3;
  static const int _tabMe = 4;

  final List<GlobalKey<NavigatorState>> _navigatorKeyObjects = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  Widget build(BuildContext context) {
    return DesktopNavigatorProvider(
      navigatorState: this,
        child: AppNavigatorScope(
        navigator: DesktopTabAppNavigator(),
        child: IndexedStack(
        index: widget.selectedIndex,
        children: [
          Navigator(
            key: _navigatorKeyObjects[_tabRecent],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const DesktopRecentCallsPage(),
              );
            },
          ),
          Navigator(
            key: _navigatorKeyObjects[_tabContacts],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const DesktopContactsPage(),
              );
            },
          ),
          Navigator(
            key: _navigatorKeyObjects[_tabGroups],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const DesktopGroupListPage(),
              );
            },
          ),
          Navigator(
            key: _navigatorKeyObjects[_tabVoice],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const VoiceMessagesPage(),
              );
            },
          ),
          Navigator(
            key: _navigatorKeyObjects[_tabMe],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const DesktopSettingsPage(),
              );
            },
          ),
        ],
      ),
      ),
    );
  }
}