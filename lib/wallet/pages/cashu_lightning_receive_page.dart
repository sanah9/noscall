import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/cashu_lightning_receive_controller.dart';
import '../domain/cashu_models.dart';
import '../domain/wallet_errors.dart';
import '../infrastructure/mobile/mobile_cashu_lightning_receive_controller_factory.dart';

final class CashuLightningReceivePage extends StatefulWidget {
  const CashuLightningReceivePage({super.key, this.controllerFactory});

  final CashuLightningReceiveControllerFactory? controllerFactory;

  @override
  State<CashuLightningReceivePage> createState() =>
      _CashuLightningReceivePageState();
}

final class _CashuLightningReceivePageState
    extends State<CashuLightningReceivePage> {
  final TextEditingController _amountController = TextEditingController();
  CashuLightningReceiveController? _controller;
  List<CashuLightningReceiveMintOption> _options = const [];
  List<CashuLightningReceiveQuoteRecord> _quoteRecords = const [];
  CashuMintUrl? _selectedMintUrl;
  CashuMintQuote? _quote;
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
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final factory =
          widget.controllerFactory ??
          MobileCashuLightningReceiveControllerFactory.create;
      final controller = await factory();
      final options = await controller.loadReceiveOptions();
      final records = await controller.loadQuoteRecords();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _options = options;
        _quoteRecords = records;
        _selectedMintUrl = options.isEmpty ? null : options.first.mint.url;
        _quote = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Lightning receive is unavailable.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receive Lightning')),
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
    if (_options.isEmpty) {
      return const _CenteredMessage(
        icon: Icons.bolt_outlined,
        message:
            'No enabled Mint supports Lightning receive. Add or refresh a Mint with NUT-04 support first.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Create a Lightning invoice'),
            subtitle: Text(
              'After the invoice is paid, mint the paid quote into your Cashu wallet.',
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
          items: _options
              .map(
                (option) => DropdownMenuItem(
                  value: option.mint.url,
                  child: Text(option.mint.name ?? option.mint.url.toString()),
                ),
              )
              .toList(growable: false),
          onChanged: _mutating
              ? null
              : (value) => setState(() {
                  _selectedMintUrl = value;
                  _quote = null;
                }),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Amount',
            suffixText: 'sat',
          ),
          onChanged: (_) => setState(() => _quote = null),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _mutating ? null : _createQuote,
          icon: _mutating
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.bolt),
          label: const Text('Create invoice'),
        ),
        if (_quote case final quote?) ...[
          const SizedBox(height: 20),
          _QuoteCard(
            quote: quote,
            onCopy: () => _copyInvoice(quote.request),
            onCheck: _mutating ? null : _checkQuote,
            onMint: _mutating || quote.state != CashuQuoteState.paid
                ? null
                : _mintQuote,
          ),
        ],
        if (_visibleQuoteRecords.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Recent invoices',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final record in _visibleQuoteRecords) ...[
            _QuoteCard(
              quote: _quoteFromRecord(record),
              onCopy: () => _copyInvoice(record.request),
              onCheck: _mutating ? null : () => _checkRecord(record),
              onMint: _mutating || record.state != CashuQuoteState.paid
                  ? null
                  : () => _mintRecord(record),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  List<CashuLightningReceiveQuoteRecord> get _visibleQuoteRecords =>
      _quoteRecords
          .where((record) => record.quoteId != _quote?.quoteId)
          .toList(growable: false);

  Future<void> _createQuote() async {
    final mintUrl = _selectedMintUrl;
    final amount = int.tryParse(_amountController.text.trim());
    if (mintUrl == null || amount == null) {
      _showSnackBar('Enter a valid amount.');
      return;
    }
    setState(() => _mutating = true);
    try {
      final quote = await _controller!.createQuote(
        mintUrl: mintUrl,
        amount: CashuAmount.positiveSats(amount),
      );
      final records = await _controller!.loadQuoteRecords();
      if (mounted) {
        setState(() {
          _quote = quote;
          _quoteRecords = records;
        });
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _checkQuote() async {
    final quote = _quote;
    if (quote == null) return;
    setState(() => _mutating = true);
    try {
      final updated = await _controller!.checkQuote(
        mintUrl: quote.mintUrl,
        quoteId: quote.quoteId,
      );
      final records = await _controller!.loadQuoteRecords();
      if (!mounted) return;
      setState(() {
        _quote = updated;
        _quoteRecords = records;
      });
      _showSnackBar(_statusMessage(updated.state));
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _mintQuote() async {
    final quote = _quote;
    if (quote == null) return;
    setState(() => _mutating = true);
    try {
      final amount = await _controller!.mintQuote(
        mintUrl: quote.mintUrl,
        quoteId: quote.quoteId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Received ${amount.value} sat.')));
      Navigator.of(context).pop(true);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _checkRecord(CashuLightningReceiveQuoteRecord record) async {
    setState(() => _mutating = true);
    try {
      final updated = await _controller!.checkQuote(
        mintUrl: record.mintUrl,
        quoteId: record.quoteId,
      );
      final records = await _controller!.loadQuoteRecords();
      if (!mounted) return;
      setState(() => _quoteRecords = records);
      _showSnackBar(_statusMessage(updated.state));
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _mintRecord(CashuLightningReceiveQuoteRecord record) async {
    setState(() => _mutating = true);
    try {
      final amount = await _controller!.mintQuote(
        mintUrl: record.mintUrl,
        quoteId: record.quoteId,
      );
      final records = await _controller!.loadQuoteRecords();
      if (!mounted) return;
      setState(() => _quoteRecords = records);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Received ${amount.value} sat.')));
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _copyInvoice(String invoice) async {
    await Clipboard.setData(ClipboardData(text: invoice));
    _showSnackBar('Invoice copied.');
  }

  CashuMintQuote _quoteFromRecord(CashuLightningReceiveQuoteRecord record) {
    return CashuMintQuote(
      quoteId: record.quoteId,
      mintUrl: record.mintUrl,
      amount: record.amount,
      request: record.request,
      state: record.state,
      expiry: record.expiry,
    );
  }

  void _showError(Object error) {
    final message = switch (error) {
      CashuProtocolException(:final message) => message,
      UnknownMintException() => 'This Mint is not configured.',
      DisabledMintException() => 'Enable this Mint before receiving.',
      UnsupportedMintException() =>
        'This Mint does not support Lightning receive.',
      WalletNotReadyException() => 'Create or restore a wallet first.',
      ArgumentError() => 'Enter a positive amount.',
      _ => 'Lightning receive failed. Please try again.',
    };
    _showSnackBar(message);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _statusMessage(CashuQuoteState state) {
    return switch (state) {
      CashuQuoteState.unpaid => 'Invoice is still unpaid.',
      CashuQuoteState.pending => 'Payment is pending.',
      CashuQuoteState.paid => 'Invoice is paid. You can mint it now.',
      CashuQuoteState.issued => 'Quote has already been issued.',
      CashuQuoteState.expired => 'Invoice expired.',
      CashuQuoteState.failed => 'Invoice failed.',
      CashuQuoteState.unknown => 'Invoice status is unknown.',
    };
  }
}

final class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.quote,
    required this.onCopy,
    required this.onCheck,
    required this.onMint,
  });

  final CashuMintQuote quote;
  final VoidCallback onCopy;
  final VoidCallback? onCheck;
  final VoidCallback? onMint;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text('${quote.amount.value} sat'),
              subtitle: Text(
                'Status: ${_quoteStateLabel(quote.state)}\nExpires: ${quote.expiry.toLocal()}',
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(quote.request, minLines: 3, maxLines: 6),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy invoice'),
                ),
                OutlinedButton.icon(
                  onPressed: onCheck,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check payment'),
                ),
                FilledButton.icon(
                  onPressed: onMint,
                  icon: const Icon(Icons.download_done),
                  label: const Text('Mint paid quote'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _quoteStateLabel(CashuQuoteState state) {
    return switch (state) {
      CashuQuoteState.unpaid => 'unpaid',
      CashuQuoteState.pending => 'pending',
      CashuQuoteState.paid => 'paid',
      CashuQuoteState.issued => 'issued',
      CashuQuoteState.expired => 'expired',
      CashuQuoteState.failed => 'failed',
      CashuQuoteState.unknown => 'unknown',
    };
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
