import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/call_payments/pages/call_payment_settings_page.dart';
import 'package:noscall/call_history/models/call_entry.dart';
import 'package:noscall/contacts/pages/contact_select_page.dart';
import 'package:noscall/contacts/user_detail_page.dart';
import 'package:noscall/core/navigation/app_navigator.dart';
import 'package:noscall/core/navigation/navigation_scope.dart';
import 'package:noscall/profile/profile_settings_page.dart';
import 'package:noscall/setting/pages/ice_server_management_page.dart';
import 'package:noscall/setting/pages/relay_management_page.dart';
import 'package:noscall/setting/pages/theme_settings_page.dart';
import 'package:noscall/core/call/messages/model/message_db_isar.dart';
import 'package:noscall/voice_messages/send_voice_message_page.dart';
import 'package:noscall/voice_messages/voice_message_detail_page.dart';

/// [AppNavigator] for desktop: pushes in current tab or on root by [NavigationScope].
/// - Tab-internal: push onto the Navigator that **contains the caller** (from [BuildContext]),
///   i.e. [Navigator.of(context)] — no dependency on selected tab index.
/// - Global: push onto root GoRouter (full-screen overlay).
/// Effective scope: call-site > page preference ([NavigationScopeDefaults]) > default (tabInternal).
class DesktopTabAppNavigator extends AppNavigator {
  DesktopTabAppNavigator();

  static const _routeContactSelect = '/contact-select';
  static const _routeSendVoice = '/send-voice-message';
  static const _routeVoiceDetail = '/voice-message-detail';
  static const _routeUserDetail = '/user-detail';
  static const _routeProfile = '/profile-settings';
  static const _routeRelay = '/relay-management';
  static const _routeIce = '/ice-server-management';
  static const _routeTheme = '/settings/theme';
  static const _routeWallet = '/wallet';
  static const _routeCallPaymentSettings = '/call-payments/settings';

  bool _useTab(NavigationScope scope, String routePath) {
    final effective = NavigationScopeDefaults.resolve(
      callSite: scope,
      routePath: routePath,
      isDesktop: true,
    );
    return effective == NavigationScope.tabInternal;
  }

  @override
  Future<List<String>?> pushContactSelect(
    BuildContext context, {
    NavigationScope scope = NavigationScope.automatic,
  }) async {
    if (_useTab(scope, _routeContactSelect)) {
      return Navigator.of(context).push<List<String>>(
        MaterialPageRoute(builder: (context) => const ContactSelectPage()),
      );
    }
    return context.push<List<String>>(
      _routeContactSelect,
      extra: <String, dynamic>{},
    );
  }

  @override
  void pushSendVoiceMessage(
    BuildContext context,
    String receiverPubkey, {
    NavigationScope scope = NavigationScope.automatic,
  }) {
    if (_useTab(scope, _routeSendVoice)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              SendVoiceMessagePage(receiverPubkey: receiverPubkey),
        ),
      );
    } else {
      context.push(_routeSendVoice, extra: {'receiverPubkey': receiverPubkey});
    }
  }

  @override
  void pushVoiceMessageDetail(
    BuildContext context,
    MessageDBISAR message, {
    NavigationScope scope = NavigationScope.automatic,
  }) {
    if (_useTab(scope, _routeVoiceDetail)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VoiceMessageDetailPage(message: message),
        ),
      );
    } else {
      context.push(_routeVoiceDetail, extra: {'message': message});
    }
  }

  @override
  Future<void> pushUserDetail(
    BuildContext context,
    String pubkey, {
    Object? callHistory,
    NavigationScope scope = NavigationScope.automatic,
  }) async {
    if (_useTab(scope, _routeUserDetail)) {
      final history = callHistory is List<CallEntry> ? callHistory : null;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              UserDetailPage(pubkey: pubkey, callHistory: history),
        ),
      );
    } else {
      await context.push(
        _routeUserDetail,
        extra: {
          'pubkey': pubkey,
          if (callHistory != null) 'callHistory': callHistory,
        },
      );
    }
  }

  @override
  void pushProfileSettings(
    BuildContext context, {
    NavigationScope scope = NavigationScope.automatic,
  }) {
    if (_useTab(scope, _routeProfile)) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ProfileSettingsPage()),
      );
    } else {
      context.push(_routeProfile);
    }
  }

  @override
  void pushRelayManagement(
    BuildContext context, {
    NavigationScope scope = NavigationScope.automatic,
  }) {
    if (_useTab(scope, _routeRelay)) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const RelayManagementPage()),
      );
    } else {
      context.push(_routeRelay);
    }
  }

  @override
  void pushIceServerManagement(
    BuildContext context, {
    NavigationScope scope = NavigationScope.automatic,
  }) {
    if (_useTab(scope, _routeIce)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const IceServerManagementPage(),
        ),
      );
    } else {
      context.push(_routeIce);
    }
  }

  @override
  void pushThemeSettings(
    BuildContext context, {
    NavigationScope scope = NavigationScope.automatic,
  }) {
    if (_useTab(scope, _routeTheme)) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ThemeSettingsPage()),
      );
    } else {
      context.push(_routeTheme);
    }
  }

  @override
  void pushWallet(
    BuildContext context, {
    NavigationScope scope = NavigationScope.automatic,
  }) {
    context.push(_routeWallet);
  }

  @override
  void pushCallPaymentSettings(
    BuildContext context, {
    NavigationScope scope = NavigationScope.automatic,
  }) {
    if (_useTab(scope, _routeCallPaymentSettings)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CallPaymentSettingsPage(),
        ),
      );
    } else {
      context.push(_routeCallPaymentSettings);
    }
  }
}
