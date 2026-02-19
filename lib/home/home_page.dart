import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:noscall/call/call_manager.dart';
import 'package:noscall/call_history/widget/recent_calls_page.dart';
import 'package:noscall/contacts/contact_navigator.dart';
import 'package:noscall/setting/setting_page.dart';
import 'package:noscall/desktop/desktop_home_page.dart';
import 'package:noscall/utils/profile_sync_mixin.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

bool get isDesktop {
  if (kIsWeb) return false;
  return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
}

class _HomePageState extends State<HomePage> with ProfileSyncOnConnectMixin<HomePage> {
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    initProfileSync();
    CallKitManager.instance.callHistoryManager.loadUnreadMissedCount();
  }

  @override
  void dispose() {
    disposeProfileSync();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == 0 && index != 0) {
      CallKitManager.instance.callHistoryManager.clearUnreadMissed();
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return const DesktopHomePage();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          RecentCallsPage(),
          ContactNavigator(),
          SettingPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: colorScheme.surfaceContainer,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        selectedLabelStyle: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: theme.textTheme.labelSmall,
        items: [
          BottomNavigationBarItem(
            icon: ValueListenableBuilder<int>(
              valueListenable: CallKitManager.instance.callHistoryManager.unreadMissedCountNotifier,
              builder: (context, unreadCount, child) {
                final icon = _selectedIndex == 0
                    ? const Icon(CupertinoIcons.clock_fill)
                    : const Icon(CupertinoIcons.clock);
                if (unreadCount <= 0) return icon;
                return Badge(
                  isLabelVisible: true,
                  smallSize: 8,
                  child: icon,
                );
              },
            ),
            label: 'Recent',
          ),
          BottomNavigationBarItem(
            icon: _selectedIndex == 1
                ? const Icon(Icons.contacts)
                : const Icon(Icons.contacts_outlined),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: _selectedIndex == 2
                ? const Icon(Icons.person)
                : const Icon(Icons.person_outline),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}