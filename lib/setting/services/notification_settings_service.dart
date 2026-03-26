import 'package:flutter/foundation.dart';
import 'package:noscall/core/common/storage/preferences_store.dart';
import 'package:noscall/core/common/utils/log_utils.dart';

/// Notification preferences: enabled, sound, do-not-disturb.
class NotificationSettingsService {
  NotificationSettingsService._internal();
  factory NotificationSettingsService() => _instance;
  static final NotificationSettingsService _instance =
      NotificationSettingsService._internal();

  static const String _keyEnabled = 'noscall_notifications_enabled';
  static const String _keySound = 'noscall_notifications_sound';
  static const String _keyDoNotDisturb = 'noscall_do_not_disturb';
  final PreferencesStore _prefs = PreferencesStore.shared;

  final ValueNotifier<bool> notificationsEnabledNotifier =
      ValueNotifier<bool>(true);
  final ValueNotifier<bool> notificationSoundNotifier =
      ValueNotifier<bool>(true);
  final ValueNotifier<bool> doNotDisturbNotifier = ValueNotifier<bool>(false);

  bool get notificationsEnabled => notificationsEnabledNotifier.value;
  bool get notificationSound => notificationSoundNotifier.value;
  bool get doNotDisturb => doNotDisturbNotifier.value;

  Future<void> initialize() async {
    notificationsEnabledNotifier.value = await _prefs.getBool(_keyEnabled) ?? true;
    notificationSoundNotifier.value = await _prefs.getBool(_keySound) ?? true;
    doNotDisturbNotifier.value = await _prefs.getBool(_keyDoNotDisturb) ?? false;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final ok = await _prefs.setBool(_keyEnabled, value);
    if (ok) {
      notificationsEnabledNotifier.value = value;
    } else {
      LogUtils.w(() => 'NotificationSettingsService.setNotificationsEnabled failed');
    }
  }

  Future<void> setNotificationSound(bool value) async {
    final ok = await _prefs.setBool(_keySound, value);
    if (ok) {
      notificationSoundNotifier.value = value;
    } else {
      LogUtils.w(() => 'NotificationSettingsService.setNotificationSound failed');
    }
  }

  Future<void> setDoNotDisturb(bool value) async {
    final ok = await _prefs.setBool(_keyDoNotDisturb, value);
    if (ok) {
      doNotDisturbNotifier.value = value;
    } else {
      LogUtils.w(() => 'NotificationSettingsService.setDoNotDisturb failed');
    }
  }

  void dispose() {
    notificationsEnabledNotifier.dispose();
    notificationSoundNotifier.dispose();
    doNotDisturbNotifier.dispose();
  }
}
