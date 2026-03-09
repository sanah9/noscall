import 'package:go_router/go_router.dart';

import 'package:noscall/profile/profile_settings_page.dart';
import 'package:noscall/setting/pages/notification_settings_page.dart';
import 'package:noscall/setting/pages/accessibility_settings_page.dart';
import 'package:noscall/setting/pages/relay_management_page.dart';
import 'package:noscall/setting/pages/ice_server_management_page.dart';
import 'package:noscall/setting/pages/data_cleanup_page.dart';
import 'package:noscall/setting/pages/data_export_page.dart';
import 'package:noscall/setting/pages/log_viewer_page.dart';
import 'package:noscall/setting/pages/account_settings_page.dart';
import 'package:noscall/setting/pages/connection_settings_page.dart';
import 'package:noscall/setting/pages/appearance_settings_page.dart';
import 'package:noscall/setting/pages/theme_settings_page.dart';
import 'package:noscall/setting/pages/data_settings_page.dart';
import 'package:noscall/setting/pages/about_settings_page.dart';

/// Settings and profile routes.
List<RouteBase> get settingsRoutes => [
      GoRoute(
        path: '/notification-settings',
        name: 'notification-settings',
        builder: (context, state) => const NotificationSettingsPage(),
      ),
      GoRoute(
        path: '/accessibility-settings',
        name: 'accessibility-settings',
        builder: (context, state) => const AccessibilitySettingsPage(),
      ),
      GoRoute(
        path: '/profile-settings',
        name: 'profile-settings',
        builder: (context, state) => const ProfileSettingsPage(),
      ),
      GoRoute(
        path: '/relay-management',
        name: 'relay-management',
        builder: (context, state) => const RelayManagementPage(),
      ),
      GoRoute(
        path: '/ice-server-management',
        name: 'ice-server-management',
        builder: (context, state) => const IceServerManagementPage(),
      ),
      GoRoute(
        path: '/data-cleanup',
        name: 'data-cleanup',
        builder: (context, state) => const DataCleanupPage(),
      ),
      GoRoute(
        path: '/data-export',
        name: 'data-export',
        builder: (context, state) => const DataExportPage(),
      ),
      GoRoute(
        path: '/log-viewer',
        name: 'log-viewer',
        builder: (context, state) => const LogViewerPage(),
      ),
      GoRoute(
        path: '/settings/account',
        name: 'settings-account',
        builder: (context, state) => const AccountSettingsPage(),
      ),
      GoRoute(
        path: '/settings/connection',
        name: 'settings-connection',
        builder: (context, state) => const ConnectionSettingsPage(),
      ),
      GoRoute(
        path: '/settings/appearance',
        name: 'settings-appearance',
        builder: (context, state) => const AppearanceSettingsPage(),
      ),
      GoRoute(
        path: '/settings/theme',
        name: 'settings-theme',
        builder: (context, state) => const ThemeSettingsPage(),
      ),
      GoRoute(
        path: '/settings/data',
        name: 'settings-data',
        builder: (context, state) => const DataSettingsPage(),
      ),
      GoRoute(
        path: '/settings/about',
        name: 'settings-about',
        builder: (context, state) => const AboutSettingsPage(),
      ),
    ];
