import 'dart:io';

import 'package:noscall/core/account/account.dart';
import 'package:noscall/setting/services/notification_settings_service.dart';
import 'package:permission_handler/permission_handler.dart';

import 'local_notification_service.dart';
import 'nostr_relay_push_service.dart';
import 'push_token_service.dart';
import 'unified_push_distributor_service.dart';

enum CallDiagnosticStatus { ready, attention, unknown, unsupported }

class CallDiagnostic {
  const CallDiagnostic(this.id, this.title, this.detail, this.status);
  final String id;
  final String title;
  final String detail;
  final CallDiagnosticStatus status;
}

class CallDiagnosticsSnapshot {
  const CallDiagnosticsSnapshot({required this.mobile, required this.checks});
  final bool mobile;
  final List<CallDiagnostic> checks;

  static CallDiagnostic subscription(
    String relay,
    DateTime? acceptedAt,
    DateTime now,
  ) {
    final recent =
        acceptedAt != null &&
        !acceptedAt.isAfter(now) &&
        now.difference(acceptedAt) <= NostrRelayPushService.resyncInterval;
    return CallDiagnostic(
      'relay:$relay',
      relay,
      acceptedAt == null
          ? 'No accepted subscription recorded'
          : 'Last accepted: ${acceptedAt.toLocal().toIso8601String().split('.').first}',
      recent ? CallDiagnosticStatus.ready : CallDiagnosticStatus.attention,
    );
  }
}

abstract class CallDiagnosticsBackend {
  Future<CallDiagnosticsSnapshot> read();
  Future<void> repair();
  Future<void> testLocalNotification();
}

class DefaultCallDiagnosticsBackend implements CallDiagnosticsBackend {
  bool get _mobile => Platform.isAndroid || Platform.isIOS;

  Future<CallDiagnostic> _permission(
    Permission permission,
    String id,
    String label,
  ) async {
    try {
      final status = await permission.status;
      return CallDiagnostic(
        id,
        label,
        status.isGranted ? 'Allowed' : 'Not allowed',
        status.isGranted
            ? CallDiagnosticStatus.ready
            : CallDiagnosticStatus.attention,
      );
    } catch (_) {
      return CallDiagnostic(
        id,
        label,
        'Status unavailable',
        CallDiagnosticStatus.unknown,
      );
    }
  }

  @override
  Future<CallDiagnosticsSnapshot> read() async {
    final pubkey = Account.sharedInstance.currentPubkey;
    final settings = NotificationSettingsService();
    final checks = <CallDiagnostic>[
      await _permission(Permission.microphone, 'microphone', 'Microphone'),
      if (_mobile)
        await _permission(
          Permission.notification,
          'permission',
          'System notifications',
        ),
      CallDiagnostic(
        'enabled',
        'App notifications',
        settings.notificationsEnabled ? 'Enabled' : 'Disabled',
        settings.notificationsEnabled
            ? CallDiagnosticStatus.ready
            : CallDiagnosticStatus.attention,
      ),
      CallDiagnostic(
        'dnd',
        'Do not disturb',
        settings.doNotDisturb ? 'Enabled' : 'Off',
        settings.doNotDisturb
            ? CallDiagnosticStatus.attention
            : CallDiagnosticStatus.ready,
      ),
    ];
    if (_mobile) {
      const configured =
          String.fromEnvironment('NOSCALL_PUSH_SERVER_URL') != '';
      checks.add(
        const CallDiagnostic(
          'server',
          'Push service',
          configured
              ? 'Configured in this build'
              : 'Not configured in this build',
          configured
              ? CallDiagnosticStatus.ready
              : CallDiagnosticStatus.attention,
        ),
      );
      if (Platform.isAndroid) {
        final distributor = await UnifiedPushDistributorService()
            .getStoredDistributor();
        checks.add(
          CallDiagnostic(
            'provider',
            'Push provider',
            distributor ?? 'Not selected',
            distributor == null
                ? CallDiagnosticStatus.attention
                : CallDiagnosticStatus.ready,
          ),
        );
      }
      final registration = await PushTokenService().getCurrentRegistration();
      checks.add(
        CallDiagnostic(
          'registration',
          'Device registration',
          registration == null
              ? 'No registration recorded'
              : 'Registration recorded locally',
          registration == null
              ? CallDiagnosticStatus.attention
              : CallDiagnosticStatus.ready,
        ),
      );
      if (Account.sharedInstance.currentPrivkey.isEmpty) {
        checks.add(
          const CallDiagnostic(
            'signer',
            'Relay subscription signing',
            'External signer subscriptions are not supported by this build',
            CallDiagnosticStatus.unsupported,
          ),
        );
      }
      final subscriptions = await NostrRelayPushService()
          .subscriptionDiagnostics();
      if (subscriptions.isEmpty) {
        checks.add(
          const CallDiagnostic(
            'relays',
            'Relay subscriptions',
            'No relay subscription recorded',
            CallDiagnosticStatus.attention,
          ),
        );
      }
      for (final entry in subscriptions.entries) {
        checks.add(
          CallDiagnosticsSnapshot.subscription(
            entry.key,
            entry.value,
            DateTime.now(),
          ),
        );
      }
    } else {
      checks.add(
        const CallDiagnostic(
          'desktop',
          'Background call push',
          'Not supported on this platform; keep NosCall open for in-app calls',
          CallDiagnosticStatus.unsupported,
        ),
      );
    }
    checks.add(
      const CallDiagnostic(
        'remote',
        'Remote delivery',
        'Not verified. A call from another device is required.',
        CallDiagnosticStatus.unknown,
      ),
    );
    if (Account.sharedInstance.currentPubkey != pubkey) {
      throw StateError('Account changed');
    }
    return CallDiagnosticsSnapshot(mobile: _mobile, checks: checks);
  }

  @override
  Future<void> repair() async {
    if (!_mobile) throw UnsupportedError('Push repair is mobile-only');
    if (!NotificationSettingsService().notificationsEnabled) {
      throw StateError('Notifications disabled');
    }
    if (!await PushTokenService().initializePlatformPush()) {
      throw StateError('Push initialization failed');
    }
    if (Platform.isIOS) {
      await PushTokenService().uploadPendingVoIPTokenIfNeeded();
      final token = await PushTokenService().getLastUploadedToken();
      if (token != null) await PushTokenService().uploadVoIPToken(token);
    }
    await NostrRelayPushService().sync(force: true);
  }

  @override
  Future<void> testLocalNotification() =>
      LocalNotificationService.instance.showDiagnosticNotification();
}
