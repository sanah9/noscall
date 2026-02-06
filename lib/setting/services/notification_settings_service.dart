import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notification preferences: enabled, sound, do-not-disturb.
class NotificationSettingsService {
  NotificationSettingsService._internal();
  factory NotificationSettingsService() => _instance;
  static final NotificationSettingsService _instance =
      NotificationSettingsService._internal();

  static const String _keyEnabled = 'noscall_notifications_enabled';
  static const String _keySound = 'noscall_notifications_sound';
  static const String _keyDoNotDisturb = 'noscall_do_not_disturb';

  final ValueNotifier<bool> notificationsEnabledNotifier =
      ValueNotifier<bool>(true);
  final ValueNotifier<bool> notificationSoundNotifier =
      ValueNotifier<bool>(true);
  final ValueNotifier<bool> doNotDisturbNotifier = ValueNotifier<bool>(false);

  bool get notificationsEnabled => notificationsEnabledNotifier.value;
  bool get notificationSound => notificationSoundNotifier.value;
  bool get doNotDisturb => doNotDisturbNotifier.value;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      notificationsEnabledNotifier.value =
          prefs.getBool(_keyEnabled) ?? true;
      notificationSoundNotifier.value =
          prefs.getBool(_keySound) ?? true;
      doNotDisturbNotifier.value =
          prefs.getBool(_keyDoNotDisturb) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('NotificationSettingsService init error: $e');
      }
    }
  }

  Future<void> setNotificationsEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyEnabled, value);
      notificationsEnabledNotifier.value = value;
    } catch (_) {}
  }

  Future<void> setNotificationSound(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySound, value);
      notificationSoundNotifier.value = value;
    } catch (_) {}
  }

  Future<void> setDoNotDisturb(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDoNotDisturb, value);
      doNotDisturbNotifier.value = value;
    } catch (_) {}
  }

  void dispose() {
    notificationsEnabledNotifier.dispose();
    notificationSoundNotifier.dispose();
    doNotDisturbNotifier.dispose();
  }
}
