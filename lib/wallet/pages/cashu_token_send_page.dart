import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/cashu_token_controller.dart';
import '../domain/cashu_models.dart';
import '../domain/wallet_errors.dart';
import '../infrastructure/mobile/mobile_cashu_token_controller_factory.dart';

final class CashuTokenSendPage extends StatefulWidget {
  const CashuTokenSendPage({super.key, this.controllerFactory});

  final CashuTokenControllerFactory? controllerFactory;

  @override
  State<CashuTokenSendPage> createState() => _CashuTokenSendPageState();
}

final class _CashuTokenSendPageState extends State<CashuTokenSendPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  CashuTokenController? _controller;
  List<CashuTokenMintOption> _mintOptions = const [];
  CashuMintUrl? _selectedMintUrl;
  CashuPreparedSend? _prepared;
  bool _loading = true;
  bool _mutating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final factory =
          widget.controllerFactory ?? MobileCashuTokenControllerFactory.create;
      final controller = await factory();
      final options = await controller.loadSendOptions();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _mintOptions = options;
        _selectedMintUrl = options.isEmpty ? null : options.first.mint.url;
        _loading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Cashu token send is unavailable.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Cashu token')),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage case final message?) {
      return _CenteredMessage(
        icon: Icons.error_outline,
        message: message,
        actionLabel: 'Retry',
        onAction: _initialize,
      );
    }
    if (_mintOptions.isEmpty) {
      return const _CenteredMessage(
        icon: Icons.hub_outlined,
        message: 'Add and enable a Mint before sending Cashu tokens.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Card(
          child: ListTile(
            leading: Icon(Icons.warning_amber_rounded),
            title: Text('Token sends are bearer cash'),
            subtitle: Text(
              'Anyone with the generated token can claim it. Reclaim it if the recipient does not use it.',
            ),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<CashuMintUrl>(
          initialValue: _selectedMintUrl,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Mint',
          ),
          items: _mintOptions
              .map(
                (option) => DropdownMenuItem(
                  value: option.mint.url,
                  child: Text(
                    '${option.mint.name ?? option.mint.url.uri.host} · ${option.balanceSats} sat',
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: _mutating
              ? null
              : (value) => setState(() {
                  _selectedMintUrl = value;
                  _prepared = null;
                }),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Amount',
            suffixText: 'sat',
          ),
          onChanged: (_) => setState(() => _prepared = null),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _memoController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Memo (optional)',
          ),
          onChanged: (_) => setState(() => _prepared = null),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _mutating ? null : _prepareSend,
          icon: _mutating
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.outbox_outlined),
          label: const Text('Generate token'),
        ),
        if (_prepared case final prepared?) ...[
          const SizedBox(height: 20),
          Text(
            'Generated token',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SelectableText(prepared.token, minLines: 4, maxLines: 8),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _copy(prepared.token),
                icon: const Icon(Icons.copy),
                label: const Text('Copy token'),
              ),
              OutlinedButton.icon(
                onPressed: _mutating ? null : _checkStatus,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Check status'),
              ),
              OutlinedButton.icon(
                onPressed: _mutating ? null : _reclaim,
                icon: const Icon(Icons.undo),
                label: const Text('Reclaim'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _prepareSend() async {
    final mintUrl = _selectedMintUrl;
    final amount = int.tryParse(_amountController.text.trim());
    if (mintUrl == null || amount == null || amount <= 0) {
      _showError(ArgumentError('Enter a positive sat amount.'));
      return;
    }

    setState(() => _mutating = true);
    try {
      final prepared = await _controller!.prepareSend(
        mintUrl: mintUrl,
        amount: CashuAmount.positiveSats(amount),
        memo: _memoController.text,
      );
      if (mounted) setState(() => _prepared = prepared);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _checkStatus() async {
    final prepared = _prepared;
    final mintUrl = _selectedMintUrl;
    if (prepared == null || mintUrl == null) return;

    setState(() => _mutating = true);
    try {
      final status = await _controller!.checkSendStatus(
        mintUrl: mintUrl,
        operationId: prepared.operationId,
      );
      if (!mounted) return;
      final message = switch (status) {
        CashuSendState.claimed => 'Token has been claimed.',
        CashuSendState.recoverable => 'Token is still recoverable.',
        CashuSendState.reclaimed => 'Token has been reclaimed.',
        CashuSendState.prepared => 'Token is prepared.',
        CashuSendState.unknown => 'Token status is unknown.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _reclaim() async {
    final prepared = _prepared;
    final mintUrl = _selectedMintUrl;
    if (prepared == null || mintUrl == null) return;

    setState(() => _mutating = true);
    try {
      final amount = await _controller!.reclaimSend(
        mintUrl: mintUrl,
        operationId: prepared.operationId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reclaimed ${amount.value} sat.')));
      Navigator.of(context).pop(true);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _copy(String token) async {
    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Token copied.')));
  }

  void _showError(Object error) {
    if (!mounted) return;
    final message = switch (error) {
      CashuProtocolException(:final message) => message,
      UnknownMintException() => 'This Mint is not configured.',
      DisabledMintException() => 'Enable this Mint before sending.',
      InsufficientCashuBalanceException(
        :final availableSats,
        :final requestedSats,
      ) =>
        'Insufficient balance: $availableSats sat available, $requestedSats sat requested.',
      WalletNotReadyException() => 'Create or restore a wallet first.',
      ArgumentError() => 'Enter a positive sat amount.',
      _ => 'Token operation failed. Please try again.',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
