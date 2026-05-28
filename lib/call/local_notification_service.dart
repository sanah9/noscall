import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:noscall/core/common/utils/log_utils.dart';
import 'package:noscall/setting/services/notification_settings_service.dart';

class LocalNotificationService {
  static final LocalNotificationService instance = LocalNotificationService._();
  LocalNotificationService._();

  static const String _voiceChannelId = 'noscall_voice_messages';
  static const String _voiceChannelName = 'Voice Messages';
  static const String _callChannelId = 'noscall_incoming_calls';
  static const String _callChannelName = 'Incoming Calls';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(initSettings);

      if (Platform.isAndroid) {
        final androidPlugin = _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            _voiceChannelId,
            _voiceChannelName,
            importance: Importance.high,
          ),
        );
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            _callChannelId,
            _callChannelName,
            importance: Importance.max,
          ),
        );
      }

      _initialized = true;
      LogUtils.i(() => 'LocalNotificationService: initialized');
    } catch (e, stack) {
      LogUtils.e(() => 'LocalNotificationService: init failed: $e\n$stack');
    }
  }

  Future<void> showVoiceMessage({
    required String senderPubkey,
    required String senderName,
  }) async {
    if (!_initialized) return;
    if (!NotificationSettingsService().notificationsEnabled) return;
    if (NotificationSettingsService().doNotDisturb) return;

    try {
      // Use pubkey hash as ID so messages from the same sender update one notification
      final id = senderPubkey.hashCode.abs() % 100000;
      await _plugin.show(
        id,
        senderName,
        'Sent you a voice message',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _voiceChannelId,
            _voiceChannelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      LogUtils.w(
          () => 'LocalNotificationService: showVoiceMessage failed: $e');
    }
  }

  /// Minimal notification shown from a background isolate (no app context).
  /// Creates its own plugin instance — does not use [instance].
  static Future<void> showIncomingCallBackground() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_notification'),
        ),
      );
      await plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _callChannelId,
              _callChannelName,
              importance: Importance.max,
            ),
          );
      await plugin.show(
        1,
        'NosCall',
        'Incoming call',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _callChannelId,
            _callChannelName,
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true,
          ),
        ),
      );
    } catch (_) {}
  }
}
