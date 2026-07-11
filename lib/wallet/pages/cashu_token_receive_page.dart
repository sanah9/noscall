import 'dart:async';

import 'package:flutter/material.dart';

import '../application/cashu_token_controller.dart';
import '../domain/cashu_models.dart';
import '../domain/wallet_errors.dart';
import '../infrastructure/mobile/mobile_cashu_token_controller_factory.dart';

final class CashuTokenReceivePage extends StatefulWidget {
  const CashuTokenReceivePage({super.key, this.controllerFactory});

  final CashuTokenControllerFactory? controllerFactory;

  @override
  State<CashuTokenReceivePage> createState() => _CashuTokenReceivePageState();
}

final class _CashuTokenReceivePageState extends State<CashuTokenReceivePage> {
  final TextEditingController _tokenController = TextEditingController();
  CashuTokenController? _controller;
  CashuTokenSummary? _preview;
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
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final factory =
          widget.controllerFactory ?? MobileCashuTokenControllerFactory.create;
      final controller = await factory();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _loading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Cashu token receive is unavailable.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receive Cashu token')),
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

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Paste a Cashu token'),
            subtitle: Text(
              'Only receive tokens from Mints you have already configured and enabled.',
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _tokenController,
          minLines: 4,
          maxLines: 8,
          autocorrect: false,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Cashu token',
            hintText: 'cashu...',
          ),
          onChanged: (_) => setState(() => _preview = null),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _mutating ? null : _previewToken,
          icon: _mutating
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search),
          label: const Text('Preview token'),
        ),
        if (_preview case final preview?) ...[
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: Text('${preview.amount.value} sat'),
              subtitle: Text(
                [
                  preview.mintUrl.toString(),
                  if (preview.memo != null) 'Memo: ${preview.memo}',
                ].join('\n'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _mutating ? null : _receive,
            icon: const Icon(Icons.download_done),
            label: const Text('Receive token'),
          ),
        ],
      ],
    );
  }

  Future<void> _previewToken() async {
    setState(() => _mutating = true);
    try {
      final preview = await _controller!.previewReceive(_tokenController.text);
      if (mounted) setState(() => _preview = preview);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _receive() async {
    setState(() => _mutating = true);
    try {
      final result = await _controller!.receive(_tokenController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Received ${result.amount.value} sat.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    final message = switch (error) {
      CashuProtocolException(:final message) => message,
      UnknownMintException() =>
        'This token uses a Mint that is not configured.',
      DisabledMintException() => 'Enable this Mint before receiving the token.',
      WalletNotReadyException() => 'Create or restore a wallet first.',
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
