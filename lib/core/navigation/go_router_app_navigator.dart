import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_navigator.dart';
import 'navigation_scope.dart';

/// [AppNavigator] implementation using root GoRouter (mobile or any global push).
/// [scope] is ignored: there is only one stack on mobile.
class GoRouterAppNavigator implements AppNavigator {
  GoRouterAppNavigator();

  @override
  Future<List<String>?> pushContactSelect(
    BuildContext context, {
    NavigationScope scope = NavigationScope.automatic,
  }) async {
    final result = await context.push<List<String>>(
      '/contact-select',
      extra: <String, dynamic>{},
    );
    return result;
  }

  @override
  void pushSendVoiceMessage(
    BuildContext context,
    String receiverPubkey, {
    NavigationScope scope = NavigationScope.automatic,
  }) {
    context.push('/send-voice-message', extra: {'receiverPubkey': receiverPubkey});
  }

  @override
  void pushVoiceMessageDetail(
    BuildContext context,
    String messageId, {
    NavigationScope scope = NavigationScope.automatic,
  }) {
    context.push('/voice-message-detail', extra: {'messageId': messageId});
  }

  @override
  Future<void> pushUserDetail(
    BuildContext context,
    String pubkey, {
    Object? callHistory,
    NavigationScope scope = NavigationScope.automatic,
  }) async {
    await context.push('/user-detail', extra: {
      'pubkey': pubkey,
      if (callHistory != null) 'callHistory': callHistory,
    });
  }

  @override
  void pushProfileSettings(
    BuildContext context, {
    NavigationScope scope = NavigationScope.automatic,
  }) {
    context.push('/profile-settings');
  }

  @override
  void pushRelayManagement(
    BuildContext context, {
    NavigationScope scope = NavigationScope.automatic,
  }) {
    context.push('/relay-management');
  }

  @override
  void pushIceServerManagement(
    BuildContext context, {
    NavigationScope scope = NavigationScope.automatic,
  }) {
    context.push('/ice-server-management');
  }

  @override
  void pushThemeSettings(
    BuildContext context, {
    NavigationScope scope = NavigationScope.automatic,
  }) {
    context.push('/settings/theme');
  }
}
