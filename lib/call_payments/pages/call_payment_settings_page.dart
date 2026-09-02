import 'package:flutter/material.dart';
import 'package:noscall/call_payments/application/call_payment_policy_service.dart';
import 'package:noscall/call_payments/application/call_payment_recovery_service.dart';
import 'package:noscall/call_payments/domain/call_payment_errors.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/infrastructure/isar_call_payment_repository.dart';
import 'package:noscall/call_payments/infrastructure/mobile/mobile_call_payment_runtime_factory.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/common/database/db_isar.dart';
import 'package:noscall/utils/toast.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';
import 'package:noscall/wallet/infrastructure/database/isar_wallet_configuration_repository.dart';

typedef CallPaymentPolicyServiceFactory = CallPaymentPolicyService Function();
typedef CallPaymentRecoveryRunner =
    Future<CallPaymentRecoveryReport> Function();

final class CallPaymentSettingsPage extends StatefulWidget {
  const CallPaymentSettingsPage({
    super.key,
    this.accountId,
    this.serviceFactory,
    this.recoveryRunner,
  });

  final CashuAccountId? accountId;
  final CallPaymentPolicyServiceFactory? serviceFactory;
  final CallPaymentRecoveryRunner? recoveryRunner;

  @override
  State<CallPaymentSettingsPage> createState() =>
      _CallPaymentSettingsPageState();
}

final class _CallPaymentSettingsPageState
    extends State<CallPaymentSettingsPage> {
  final TextEditingController _audioController = TextEditingController();
  final TextEditingController _videoController = TextEditingController();

  CallPaymentPolicyService? _service;
  CashuAccountId? _accountId;
  CallPaymentPolicy? _policy;
  List<CashuMintUrl> _availableMintUrls = const [];
  Set<CashuMintUrl> _selectedMintUrls = {};
  CallPaymentFreePolicy _freePolicy = CallPaymentFreePolicy.contactsFree;
  bool _enabled = false;
  bool _loading = true;
  bool _saving = false;
  bool _recovering = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _audioController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final accountId = widget.accountId ?? _currentAccountId();
      final service = widget.serviceFactory?.call() ?? _defaultService();
      final policy = await service.ensure(accountId);
      final availableMintUrls = await service.loadAvailableMintUrls(accountId);
      if (!mounted) return;
      setState(() {
        _service = service;
        _accountId = accountId;
        _policy = policy;
        _availableMintUrls = availableMintUrls;
        _selectedMintUrls = policy.acceptedMintUrls.toSet();
        _enabled = policy.enabled;
        _freePolicy = policy.freePolicy;
        _audioController.text = policy.audioPriceSatsPerMinute.toString();
        _videoController.text = policy.videoPriceSatsPerMinute.toString();
        _loading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Paid call settings could not be loaded.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paid Calls')),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage case final message?) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _buildMainSwitch(),
        const SizedBox(height: 12),
        _buildPriceFields(),
        const SizedBox(height: 12),
        _buildFreePolicy(),
        const SizedBox(height: 12),
        _buildMintSelection(),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Ordinary Cashu Token payments'),
            subtitle: Text(
              'First release payments are encrypted ordinary tokens. They are not escrowed, not locked to the receiver, and automatic refunds depend on the other client.',
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildRecoveryCard(),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildRecoveryCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.restore_outlined),
        title: const Text('Recover pending payments'),
        subtitle: const Text(
          'Checks reclaimable tokens and refreshes refund-pending states.',
        ),
        trailing: IconButton(
          tooltip: 'Recover',
          onPressed: _recovering ? null : _recoverPendingPayments,
          icon: _recovering
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_outlined),
        ),
      ),
    );
  }

  Widget _buildMainSwitch() {
    return Card(
      child: SwitchListTile(
        secondary: const Icon(Icons.paid_outlined),
        title: const Text('Require payment for incoming calls'),
        subtitle: const Text('Free-call rules still apply before payment.'),
        value: _enabled,
        onChanged: _saving ? null : (value) => setState(() => _enabled = value),
      ),
    );
  }

  Widget _buildPriceFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prices', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _audioController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Audio price',
                suffixText: 'sat/min',
                prefixIcon: Icon(Icons.call_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _videoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Video price',
                suffixText: 'sat/min',
                prefixIcon: Icon(Icons.videocam_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreePolicy() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<CallPaymentFreePolicy>(
          initialValue: _freePolicy,
          decoration: const InputDecoration(
            labelText: 'Free calls',
            prefixIcon: Icon(Icons.lock_open_outlined),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: CallPaymentFreePolicy.contactsFree,
              child: Text('Contacts free'),
            ),
            DropdownMenuItem(
              value: CallPaymentFreePolicy.everyonePays,
              child: Text('Everyone pays'),
            ),
            DropdownMenuItem(
              value: CallPaymentFreePolicy.whitelistFree,
              child: Text('Whitelist free'),
            ),
            DropdownMenuItem(
              value: CallPaymentFreePolicy.everyoneFree,
              child: Text('Everyone free'),
            ),
          ],
          onChanged: _saving || _enabled == false
              ? null
              : (value) {
                  if (value != null) setState(() => _freePolicy = value);
                },
        ),
      ),
    );
  }

  Widget _buildMintSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              leading: Icon(Icons.hub_outlined),
              title: Text('Accepted Mints'),
              subtitle: Text(
                'Paid calls use one shared Mint. No Mint is recommended automatically.',
              ),
            ),
            if (_availableMintUrls.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  'No enabled sat Mint available. Add a Mint in Wallet first.',
                ),
              )
            else
              ..._availableMintUrls.map(
                (url) => CheckboxListTile(
                  value: _selectedMintUrls.contains(url),
                  title: Text(url.uri.host),
                  subtitle: Text(url.toString()),
                  onChanged: _saving
                      ? null
                      : (selected) => _toggleMint(url, selected ?? false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleMint(CashuMintUrl url, bool selected) {
    setState(() {
      final updated = {..._selectedMintUrls};
      if (selected) {
        updated.add(url);
      } else {
        updated.remove(url);
      }
      _selectedMintUrls = updated;
    });
  }

  Future<void> _save() async {
    final policy = _policy;
    final service = _service;
    final accountId = _accountId;
    if (policy == null || service == null || accountId == null) return;

    final audioPrice = int.tryParse(_audioController.text.trim());
    final videoPrice = int.tryParse(_videoController.text.trim());
    if (audioPrice == null || videoPrice == null) {
      AppToast.showError(context, 'Enter prices as whole sat amounts.');
      return;
    }

    setState(() => _saving = true);
    try {
      final saved = await service.save(
        policy.copyWith(
          enabled: _enabled,
          freePolicy: _freePolicy,
          audioPriceSatsPerMinute: audioPrice,
          videoPriceSatsPerMinute: videoPrice,
          acceptedMintUrls: _selectedMintUrls,
        ),
      );
      if (!mounted) return;
      setState(() {
        _policy = saved;
        _enabled = saved.enabled;
        _freePolicy = saved.freePolicy;
        _selectedMintUrls = saved.acceptedMintUrls.toSet();
        _saving = false;
      });
      AppToast.showSuccess(context, 'Paid call settings saved');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.showError(context, _messageFor(error));
    }
  }

  Future<void> _recoverPendingPayments() async {
    if (_recovering) return;
    setState(() => _recovering = true);
    try {
      final runner =
          widget.recoveryRunner ??
          MobileCallPaymentRuntimeFactory.recoverPendingPayments;
      final report = await runner();
      if (!mounted) return;
      AppToast.showSuccess(context, _recoveryMessage(report));
    } catch (_) {
      if (!mounted) return;
      AppToast.showError(context, 'Payment recovery could not be completed.');
    } finally {
      if (mounted) setState(() => _recovering = false);
    }
  }

  CashuAccountId _currentAccountId() {
    return CashuAccountId.fromNostrPubkey(Account.sharedInstance.currentPubkey);
  }

  CallPaymentPolicyService _defaultService() {
    return CallPaymentPolicyService(
      policyRepository: IsarCallPaymentPolicyRepository(
        DBISAR.sharedInstance.isar,
      ),
      mintRepository: IsarMintConfigurationRepository(
        DBISAR.sharedInstance.isar,
      ),
    );
  }

  String _messageFor(Object error) {
    return switch (error) {
      NoAcceptedCallPaymentMintException() =>
        'Select at least one enabled sat Mint.',
      UnsupportedCallPaymentMintException() =>
        'Selected Mint is not available for paid calls.',
      InvalidCallPaymentPriceException() => 'Prices must be whole sat amounts.',
      InvalidCallPaymentTimingException() =>
        'Paid call timing settings are invalid.',
      CallPaymentPolicyException(:final message) => message,
      ArgumentError() => 'Prices must be whole sat amounts.',
      _ => 'Paid call settings could not be saved.',
    };
  }

  String _recoveryMessage(CallPaymentRecoveryReport report) {
    if (report.scannedSessions == 0 && report.expiredIncomingSessions == 0) {
      return 'No pending paid call payments.';
    }
    return 'Payment recovery complete: ${report.reclaimedInstallments} reclaimed, ${report.claimedInstallments} refund pending, ${report.unknownInstallments} unknown, ${report.sentRefundInstallments} refunds sent.';
  }
}
