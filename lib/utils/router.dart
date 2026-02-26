import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/auth/auth_service.dart';
import 'package:noscall/call/call_ui/calling_page.dart';
import 'package:noscall/call/calling_controller.dart';
import 'package:noscall/call_history/models/call_entry.dart';
import 'package:noscall/auth/login_home_page.dart';
import 'package:noscall/auth/signin_page.dart';
import 'package:noscall/auth/signup_page.dart';
import 'package:noscall/auth/account_info_page.dart';
import 'package:noscall/home/home_page.dart';
import 'package:noscall/contacts/add_contact_page.dart';
import 'package:noscall/contacts/qr_scan_page.dart';
import 'package:noscall/contacts/user_detail_page.dart';
import 'package:noscall/contacts/edit_nickname_page.dart';
import 'package:noscall/contacts/edit_remark_page.dart';
import 'package:noscall/setting/pages/notification_settings_page.dart';
import 'package:noscall/setting/pages/accessibility_settings_page.dart';
import 'package:noscall/contacts/pages/group_contacts_page.dart';
import 'package:noscall/contacts/pages/contact_select_page.dart';
import 'package:noscall/profile/profile_settings_page.dart';
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
import 'package:noscall/core/call/messages/model/messageDB_isar.dart';
import 'package:noscall/voice_messages/send_voice_message_page.dart';
import 'package:noscall/voice_messages/voice_message_detail_page.dart';

/// Returns state.extra as Map, or null.
Map<String, dynamic>? getRouteParams(GoRouterState state) {
  return state.extra as Map<String, dynamic>?;
}

/// Gets a single param from state.extra map by key. Returns null if missing or wrong type.
T? getRouteParam<T>(GoRouterState state, String key) {
  final params = getRouteParams(state);
  if (params == null) return null;
  final value = params[key];
  return value is T ? value : null;
}

/// If param is null, returns a Scaffold with [notFoundMessage]; otherwise builds with [builder].
Widget buildWithRequiredParam<T>(
  GoRouterState state,
  String key,
  String notFoundMessage,
  Widget Function(T param) builder,
) {
  final param = getRouteParam<T>(state, key);
  if (param == null) {
    return Scaffold(
      body: Center(child: Text(notFoundMessage)),
    );
  }
  return builder(param);
}

class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: AuthService().isAuthenticated ? '/' : '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginHomePage(),
      ),
      GoRoute(
        path: '/signin',
        name: 'signin',
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/account-info',
        name: 'account-info',
        builder: (context, state) => const AccountInfoPage(),
      ),
      GoRoute(
        path: '/call',
        name: 'call',
        builder: (context, state) {
          CallingController controller = state.extra as CallingController;
          return CallingPage(controller: controller);
        },
      ),
      GoRoute(
        path: '/add-contact',
        name: 'add-contact',
        builder: (context, state) => const AddContactPage(),
      ),
      GoRoute(
        path: '/qr-scan',
        name: 'qr-scan',
        builder: (context, state) => const QRScanPage(),
      ),
      GoRoute(
        path: '/user-detail',
        name: 'user-detail',
        builder: (context, state) {
          final pubkey = getRouteParam<String>(state, 'pubkey');
          if (pubkey == null || pubkey.isEmpty) {
            return Scaffold(
              body: Center(child: Text('User pubkey not found')),
            );
          }
          final callHistory = getRouteParam<List<CallEntry>>(state, 'callHistory');
          return UserDetailPage(pubkey: pubkey, callHistory: callHistory);
        },
      ),
      GoRoute(
        path: '/edit-nickname',
        name: 'edit-nickname',
        builder: (context, state) => buildWithRequiredParam<String>(
          state,
          'pubkey',
          'User pubkey not found',
          (pubkey) => EditNicknamePage(
            pubkey: pubkey,
            currentNickname: getRouteParam<String>(state, 'currentNickname') ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/edit-remark',
        name: 'edit-remark',
        builder: (context, state) => buildWithRequiredParam<String>(
          state,
          'pubkey',
          'User pubkey not found',
          (pubkey) => EditRemarkPage(
            pubkey: pubkey,
            currentRemark: getRouteParam<String>(state, 'currentRemark') ?? '',
          ),
        ),
      ),
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
        path: '/group-contacts',
        name: 'group-contacts',
        builder: (context, state) => buildWithRequiredParam<int>(
          state,
          'groupId',
          'Group ID not found',
          (groupId) => GroupContactsPage(
            groupId: groupId,
            groupName: getRouteParam<String>(state, 'groupName') ?? 'Group',
          ),
        ),
      ),
      GoRoute(
        path: '/contact-select',
        name: 'contact-select',
        builder: (context, state) => ContactSelectPage(
          excludePubKeys: getRouteParam<List<String>>(state, 'excludePubKeys'),
        ),
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
      GoRoute(
        path: '/voice-message-detail',
        name: 'voice-message-detail',
        builder: (context, state) {
          final params = state.extra as Map? ?? {};
          final message = params['message'] as MessageDBISAR?;
          if (message == null) {
            return const Scaffold(
              body: Center(child: Text('Message not found')),
            );
          }
          return VoiceMessageDetailPage(message: message);
        },
      ),
      GoRoute(
        path: '/send-voice-message',
        name: 'send-voice-message',
        builder: (context, state) {
          final params = state.extra as Map? ?? {};
          final receiverPubkey = params['receiverPubkey'] as String? ?? '';
          return SendVoiceMessagePage(receiverPubkey: receiverPubkey);
        },
      ),
    ],
  );

  static GoRouter get router => _router;
}