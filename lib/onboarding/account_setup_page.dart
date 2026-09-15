import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/call/contacts/contacts.dart';
import 'package:noscall/setting/services/notification_settings_service.dart';
import 'package:permission_handler/permission_handler.dart';

import 'account_backup_page.dart';
import 'account_setup_service.dart';

typedef SetupFactsLoader = Future<Set<AccountSetupStep>> Function();

class AccountSetupPage extends StatefulWidget {
  const AccountSetupPage({
    super.key,
    required this.service,
    this.onExit,
    this.loadFacts,
    this.openStep,
  });
  final AccountSetupService service;
  final VoidCallback? onExit;
  final SetupFactsLoader? loadFacts;
  final Future<bool> Function(AccountSetupStep)? openStep;

  @override
  State<AccountSetupPage> createState() => _AccountSetupPageState();
}

class _AccountSetupPageState extends State<AccountSetupPage>
    with WidgetsBindingObserver {
  AccountSetupProgress? _progress;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _refresh();
  }

  Future<Set<AccountSetupStep>> _facts() async {
    final account = Account.sharedInstance;
    final notifications =
        !Platform.isAndroid && !Platform.isIOS ||
        (await Permission.notification.status).isGranted &&
            NotificationSettingsService().notificationsEnabled;
    return {
      if ((account.me?.name ?? '').trim().isNotEmpty) AccountSetupStep.profile,
      if (notifications) AccountSetupStep.notifications,
      if (Contacts.sharedInstance.allContacts.isNotEmpty)
        AccountSetupStep.contact,
    };
  }

  Future<void> _refresh() async {
    try {
      final facts = await (widget.loadFacts ?? _facts)();
      final previous = await widget.service.load();
      final progress = await widget.service.update(
        steps: {
          for (final step in AccountSetupStep.values.where(
            (s) => s != AccountSetupStep.backup,
          ))
            step: facts.contains(step)
                ? AccountSetupStatus.completed
                : previous.status(step) == AccountSetupStatus.skipped
                ? AccountSetupStatus.skipped
                : AccountSetupStatus.pending,
        },
      );
      if (mounted) {
        setState(() {
          _progress = progress;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Setup status could not be loaded.');
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Changes could not be saved. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(AccountSetupStep step) => _run(() async {
    if (widget.openStep != null) {
      if (await widget.openStep!(step)) {
        await widget.service.update(
          steps: {step: AccountSetupStatus.completed},
        );
      }
    } else {
      switch (step) {
        case AccountSetupStep.profile:
          await context.push('/profile-settings');
        case AccountSetupStep.backup:
          final confirmed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => AccountBackupPage(
                privateKey: Account.sharedInstance.currentPrivkey,
              ),
            ),
          );
          if (confirmed == true) {
            await widget.service.update(
              steps: {step: AccountSetupStatus.completed},
            );
          }
        case AccountSetupStep.notifications:
          await context.push('/notification-settings');
        case AccountSetupStep.contact:
          await context.push('/add-contact');
      }
    }
    if (mounted) await _refresh();
  });

  Future<void> _exit() => _run(() async {
    await widget.service.update(dismissed: true);
    if (!mounted) return;
    if (widget.onExit != null) {
      widget.onExit!();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  });

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account setup'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Continue later',
            onPressed: _busy ? null : _exit,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: progress == null && _error == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Image.asset(
                      'assets/images/icon_app_logo.png',
                      height: 64,
                      width: 64,
                    ),
                    const SizedBox(height: 20),
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Retry',
                        onPressed: _busy ? null : _refresh,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                    if (progress != null) ...[
                      Text(
                        '${progress.completedCount} of 4 completed',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: progress.completedCount / 4,
                      ),
                      const SizedBox(height: 16),
                      for (final step in AccountSetupStep.values) ...[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(switch (step) {
                            AccountSetupStep.profile => Icons.person_outline,
                            AccountSetupStep.backup => Icons.key_outlined,
                            AccountSetupStep.notifications =>
                              Icons.notifications_outlined,
                            AccountSetupStep.contact =>
                              Icons.person_add_outlined,
                          }),
                          title: Text(switch (step) {
                            AccountSetupStep.profile => 'Your profile',
                            AccountSetupStep.backup => 'Account key backup',
                            AccountSetupStep.notifications =>
                              'Notification access',
                            AccountSetupStep.contact => 'First contact',
                          }),
                          subtitle: Text(switch (progress.status(step)) {
                            AccountSetupStatus.completed => 'Completed',
                            AccountSetupStatus.skipped => 'Skipped for now',
                            AccountSetupStatus.pending => 'Not completed',
                          }),
                          onTap: _busy ? null : () => _open(step),
                          trailing:
                              progress.status(step) ==
                                  AccountSetupStatus.completed
                              ? const Icon(Icons.check_circle_outline)
                              : IconButton(
                                  tooltip: 'Skip this step',
                                  icon: const Icon(Icons.skip_next),
                                  onPressed: _busy
                                      ? null
                                      : () => _run(() async {
                                          final next = await widget.service
                                              .update(
                                                steps: {
                                                  step: AccountSetupStatus
                                                      .skipped,
                                                },
                                              );
                                          if (mounted) {
                                            setState(() => _progress = next);
                                          }
                                        }),
                                ),
                        ),
                        const Divider(),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _busy ? null : _exit,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Go to contacts'),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class AccountSetupGate extends StatefulWidget {
  const AccountSetupGate({
    super.key,
    required this.pubkey,
    required this.child,
  });
  final String pubkey;
  final Widget child;
  @override
  State<AccountSetupGate> createState() => _AccountSetupGateState();
}

class _AccountSetupGateState extends State<AccountSetupGate> {
  late final AccountSetupService _service = AccountSetupService(widget.pubkey);
  late final Future<AccountSetupProgress> _progress = _service.load();
  bool _exited = false;
  @override
  Widget build(BuildContext context) => FutureBuilder<AccountSetupProgress>(
    future: _progress,
    builder: (context, snapshot) {
      if (_exited ||
          snapshot.hasError ||
          snapshot.data?.dismissed == true ||
          snapshot.data?.finished == true) {
        return widget.child;
      }
      if (!snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return AccountSetupPage(
        service: _service,
        onExit: () => setState(() => _exited = true),
      );
    },
  );
}
