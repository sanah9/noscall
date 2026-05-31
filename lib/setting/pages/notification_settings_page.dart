import 'dart:io';

import 'package:flutter/material.dart';
import 'package:noscall/call/unified_push_distributor_service.dart';
import 'package:noscall/call/widgets/push_distributor_picker.dart';
import 'package:noscall/core/navigation/app_navigator_scope.dart';
import 'package:noscall/setting/services/notification_settings_service.dart';

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
          onPressed: () =>
              AppNavigatorScope.requireOf(context).pop(context),
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
          if (Platform.isAndroid) ...[
            const Divider(indent: 16, endIndent: 16),
            _PushDistributorTile(),
          ],
        ],
      ),
    );
  }
}

class _PushDistributorTile extends StatefulWidget {
  @override
  State<_PushDistributorTile> createState() => _PushDistributorTileState();
}

class _PushDistributorTileState extends State<_PushDistributorTile> {
  String? _distributor;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await UnifiedPushDistributorService().getStoredDistributor();
    if (mounted) setState(() => _distributor = d);
  }

  Future<void> _change() async {
    await UnifiedPushDistributorService().changeDistributor(context);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final label = _distributor != null
        ? distributorDisplayName(_distributor!)
        : 'None (tap to configure)';

    return ListTile(
      leading: Icon(Icons.send_to_mobile_outlined, color: colorScheme.primary),
      title: Text(
        'Push provider',
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: _distributor == null
              ? colorScheme.error
              : colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: _change,
    );
  }
}
