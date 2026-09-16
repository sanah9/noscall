import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/call/call_diagnostics_service.dart';
import 'package:noscall/call/unified_push_distributor_service.dart';
import 'package:noscall/utils/microphone_permission_service.dart';
import 'package:permission_handler/permission_handler.dart';

class CallDiagnosticsPage extends StatefulWidget {
  const CallDiagnosticsPage({super.key, this.backend});
  final CallDiagnosticsBackend? backend;
  @override
  State<CallDiagnosticsPage> createState() => _CallDiagnosticsPageState();
}

class _CallDiagnosticsPageState extends State<CallDiagnosticsPage>
    with WidgetsBindingObserver {
  late final _backend = widget.backend ?? DefaultCallDiagnosticsBackend();
  CallDiagnosticsSnapshot? _snapshot;
  bool _busy = false;
  String? _message;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _run(() async {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _run(() async {});
  }

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
      final snapshot = await _backend.read();
      if (mounted) {
        setState(() {
          _snapshot = snapshot;
          _message = success;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _message = 'Check could not complete. Review settings and retry.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _repair() => _run(
    () async {
      if (widget.backend == null && Platform.isAndroid) {
        await UnifiedPushDistributorService().ensureDistributorSelected(
          context,
        );
      }
      await _backend.repair();
    },
    success:
        'Registration refresh finished. Review the results below; remote delivery is still unverified.',
  );

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call diagnostics'),
        actions: [
          IconButton(
            tooltip: 'Refresh diagnostics',
            onPressed: _busy ? null : () => _run(() async {}),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_busy) const LinearProgressIndicator(),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _failed
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                  ),
                ),
              if (snapshot != null) ...[
                for (final check in snapshot.checks)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: Icon(
                      switch (check.status) {
                        CallDiagnosticStatus.ready =>
                          Icons.check_circle_outline,
                        CallDiagnosticStatus.attention => Icons.warning_amber,
                        CallDiagnosticStatus.unknown => Icons.help_outline,
                        CallDiagnosticStatus.unsupported =>
                          Icons.remove_circle_outline,
                      },
                      color: check.status == CallDiagnosticStatus.attention
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                    title: Text(check.title),
                    subtitle: Text(check.detail),
                  ),
                const Divider(),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    IconButton(
                      tooltip: 'System app settings',
                      onPressed: _busy ? null : openAppSettings,
                      icon: const Icon(Icons.settings_outlined),
                    ),
                    IconButton(
                      tooltip: 'Request microphone access',
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                              await MicrophonePermissionService.instance
                                  .request();
                            }),
                      icon: const Icon(Icons.mic_outlined),
                    ),
                    if (snapshot.mobile)
                      IconButton(
                        tooltip: 'Request notification access',
                        onPressed: _busy
                            ? null
                            : () => _run(() async {
                                final status = await Permission.notification
                                    .request();
                                if (status.isPermanentlyDenied) {
                                  await openAppSettings();
                                }
                              }),
                        icon: const Icon(Icons.notifications_active_outlined),
                      ),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () async {
                              await context.push('/relay-management');
                              if (mounted) _run(() async {});
                            },
                      icon: const Icon(Icons.hub_outlined),
                      label: const Text('Relays'),
                    ),
                    if (snapshot.mobile)
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _repair,
                        icon: const Icon(Icons.sync),
                        label: const Text('Refresh registration'),
                      ),
                    if (snapshot.mobile)
                      FilledButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                _backend.testLocalNotification,
                                success:
                                    'Local notification requested. Confirm it appeared on this device. Remote delivery has not been tested.',
                              ),
                        icon: const Icon(Icons.notification_add_outlined),
                        label: const Text('Test local notification'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
