import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../application/wallet_landing_controller.dart';
import '../domain/wallet_configuration.dart';
import '../infrastructure/mobile/mobile_wallet_controller_factory.dart';
import 'wallet_backup_page.dart';

final class WalletLandingPage extends StatefulWidget {
  const WalletLandingPage({super.key, this.controllerFactory});

  final WalletLandingControllerFactory? controllerFactory;

  @override
  State<WalletLandingPage> createState() => _WalletLandingPageState();
}

final class _WalletLandingPageState extends State<WalletLandingPage> {
  WalletLandingController? _controller;
  WalletLandingSnapshot? _snapshot;
  bool _loading = true;
  bool _creating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }

  Future<void> _initialize() async {
    WalletLandingController? candidate;
    try {
      final factory =
          widget.controllerFactory ?? MobileWalletControllerFactory.create;
      candidate = await factory();
      final snapshot = await candidate.load();
      if (!mounted) {
        await candidate.dispose();
        return;
      }
      setState(() {
        _controller = candidate;
        _snapshot = snapshot;
        _loading = false;
        _errorMessage = null;
      });
    } catch (_) {
      await candidate?.dispose();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Wallet could not be opened. Please try again.';
      });
    }
  }

  Future<void> _reload() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final snapshot = await controller.load();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _errorMessage = null;
      });
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Wallet refresh failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage case final message?) {
      return _CenteredMessage(
        icon: Icons.error_outline,
        message: message,
        actionLabel: 'Retry',
        onAction: _controller == null ? _initialize : _reload,
      );
    }

    final snapshot = _snapshot!;
    return switch (snapshot.status) {
      WalletLandingStatus.absent => _buildSetup(context),
      WalletLandingStatus.ready => _buildWalletHome(context, snapshot),
      WalletLandingStatus.unavailable => _CenteredMessage(
        icon: Icons.lock_outline,
        message: snapshot.unavailableReason ?? 'Wallet is unavailable.',
      ),
    };
  }

  Widget _buildSetup(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_controller?.isDevelopmentOnly == true) const _DevelopmentBanner(),
        const SizedBox(height: 16),
        Icon(
          Icons.account_balance_wallet_outlined,
          size: 72,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 20),
        Text(
          'Your Cashu wallet',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        const Text(
          'Cashu funds are issued by independent Mints. A Mint can fail, disappear, or refuse redemption. noscall does not provide a default Mint and does not custody your funds.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: _creating ? null : _createWallet,
          icon: _creating
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
          label: const Text('Create wallet'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => context.push('/wallet/restore'),
          child: const Text('Restore wallet'),
        ),
      ],
    );
  }

  Widget _buildWalletHome(
    BuildContext context,
    WalletLandingSnapshot snapshot,
  ) {
    final backupComplete =
        snapshot.backupStatus == WalletBackupStatus.confirmed;
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          if (_controller?.isDevelopmentOnly == true)
            const _DevelopmentBanner(),
          if (!backupComplete) ...[
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: const ListTile(
                leading: Icon(Icons.warning_amber_rounded),
                title: Text('Wallet backup is not complete'),
                subtitle: Text(
                  'Loss of this device may make funds impossible to recover.',
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Available balance',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '${snapshot.balanceSats} sat',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 28),
          Card(
            child: ListTile(
              leading: const Icon(Icons.hub_outlined),
              title: Text(
                snapshot.mintCount == 0
                    ? 'No Mint configured'
                    : '${snapshot.enabledMintCount} of ${snapshot.mintCount} Mints enabled',
              ),
              subtitle: Text(
                snapshot.mintCount == 0
                    ? 'Add a Mint you trust before receiving or sending Cashu.'
                    : 'Review, refresh, enable, or remove configured Mints.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await context.push('/wallet/mints');
                await _reload();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createWallet() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Cashu wallet?'),
        content: const Text(
          'This is ecash issued by third-party Mints, not bitcoin held directly on-chain. You are responsible for choosing Mints and backing up the recovery words.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;

    setState(() => _creating = true);
    try {
      final controller = _controller!;
      final mnemonic = await controller.createWallet();
      await controller.updateBackupStatus(WalletBackupStatus.shown);
      if (!mounted) return;
      final backupStatus = await context.push<WalletBackupStatus>(
        '/wallet/backup',
        extra: WalletBackupArguments(mnemonic),
      );
      if (backupStatus != null) {
        await controller.updateBackupStatus(backupStatus);
      }
      await _reload();
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Wallet creation failed.');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }
}

final class _DevelopmentBanner extends StatelessWidget {
  const _DevelopmentBanner();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: const ListTile(
        leading: Icon(Icons.science_outlined),
        title: Text('Development wallet'),
        subtitle: Text(
          'Do not use real funds. Seed storage is not production-ready.',
        ),
      ),
    );
  }
}

final class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel case final label?) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(label)),
            ],
          ],
        ),
      ),
    );
  }
}
