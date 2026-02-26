import 'package:flutter/material.dart';

import 'package:noscall/core/call/messages/model/messageDB_isar.dart';
import 'navigation_scope.dart';

/// Abstraction for app-level navigation. Callers use this interface only;
/// implementation is either [GoRouterAppNavigator] (mobile/root) or
/// [DesktopTabAppNavigator] (desktop: tab or root by scope), so UI code
/// does not branch on platform. Scope priority: call-site > page preference > default.
abstract class AppNavigator {
  /// Push contact select; returns selected pubkey list or null when cancelled.
  Future<List<String>?> pushContactSelect(
    BuildContext context, {
    NavigationScope scope = NavigationScope.automatic,
  });

  void pushSendVoiceMessage(
    BuildContext context,
    String receiverPubkey, {
    NavigationScope scope = NavigationScope.automatic,
  });

  void pushVoiceMessageDetail(
    BuildContext context,
    MessageDBISAR message, {
    NavigationScope scope = NavigationScope.automatic,
  });

  Future<void> pushUserDetail(
    BuildContext context,
    String pubkey, {
    Object? callHistory,
    NavigationScope scope = NavigationScope.automatic,
  });

  void pushProfileSettings(
    BuildContext context, {
    NavigationScope scope = NavigationScope.automatic,
  });

  void pushRelayManagement(
    BuildContext context, {
    NavigationScope scope = NavigationScope.automatic,
  });

  void pushIceServerManagement(
    BuildContext context, {
    NavigationScope scope = NavigationScope.automatic,
  });

  void pushThemeSettings(
    BuildContext context, {
    NavigationScope scope = NavigationScope.automatic,
  });
}
