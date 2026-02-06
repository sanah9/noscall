import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/notification_settings_service.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final service = NotificationSettingsService();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notification',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: service.notificationsEnabledNotifier,
            builder: (context, enabled, _) {
              return SwitchListTile(
                secondary: Icon(
                  Icons.notifications_active,
                  color: colorScheme.primary,
                ),
                title: Text(
                  'Enable notifications',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Show call and message notifications',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                value: enabled,
                onChanged: (v) => service.setNotificationsEnabled(v),
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: service.notificationSoundNotifier,
            builder: (context, sound, _) {
              return SwitchListTile(
                secondary: Icon(
                  Icons.volume_up,
                  color: colorScheme.primary,
                ),
                title: Text(
                  'Notification sound',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Play sound for incoming calls and notifications',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                value: sound,
                onChanged: (v) => service.setNotificationSound(v),
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: service.doNotDisturbNotifier,
            builder: (context, dnd, _) {
              return SwitchListTile(
                secondary: Icon(
                  Icons.do_not_disturb_on,
                  color: colorScheme.primary,
                ),
                title: Text(
                  'Do not disturb',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Mute notifications when enabled',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                value: dnd,
                onChanged: (v) => service.setDoNotDisturb(v),
              );
            },
          ),
        ],
      ),
    );
  }
}
