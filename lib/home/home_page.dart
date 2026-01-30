import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../call/call_manager.dart';
import '../call_history/widget/recent_calls_page.dart';
import '../contacts/contact_navigator.dart';
import '../setting/setting_page.dart';
import '../core/account/account.dart';
import '../core/account/account+profile.dart';
import '../core/common/network/connect.dart';
import '../desktop/desktop_home_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

bool get isDesktop {
  if (kIsWeb) return false;
  return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1;
  bool _profileSynced = false;

  @override
  void initState() {
    super.initState();
    Connect.sharedInstance.addConnectStatusListener(_onConnectStatusChanged);
    _syncProfileIfNeeded();
    CallKitManager.instance.callHistoryManager.loadUnreadMissedCount();
  }

  @override
  void dispose() {
    Connect.sharedInstance.removeConnectStatusListener(_onConnectStatusChanged);
    super.dispose();
  }

  void _onConnectStatusChanged(String relay, int status, List<RelayKind> relayKinds) {
    if (status == 1 && relayKinds.contains(RelayKind.general)) {
      _syncProfileIfNeeded();
    }
  }

  Future<void> _syncProfileIfNeeded() async {
    if (_profileSynced) return;

    final connectedRelays = Connect.sharedInstance.relays(relayKinds: [RelayKind.general]);
    if (connectedRelays.isEmpty) return;

    final me = Account.sharedInstance.me;
    if (me == null || (me.name ?? '').isEmpty) return;

    final result = await Account.sharedInstance.updateProfile(me);
    if (result != null) {
      setState(() {
        _profileSynced = true;
      });
    }
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