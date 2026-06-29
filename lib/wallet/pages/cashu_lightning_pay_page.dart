import 'package:flutter/material.dart';

import '../application/cashu_lightning_pay_controller.dart';
import '../domain/cashu_models.dart';
import '../domain/wallet_errors.dart';
import '../infrastructure/mobile/mobile_cashu_lightning_pay_controller_factory.dart';

final class CashuLightningPayPage extends StatefulWidget {
  const CashuLightningPayPage({super.key, this.controllerFactory});

  final CashuLightningPayControllerFactory? controllerFactory;

  @override
  State<CashuLightningPayPage> createState() => _CashuLightningPayPageState();
}

final class _CashuLightningPayPageState extends State<CashuLightningPayPage> {
  final TextEditingController _invoiceController = TextEditingController();
  CashuLightningPayController? _controller;
  List<CashuLightningPayMintOption> _mintOptions = const [];
  CashuMintUrl? _selectedMintUrl;
  CashuMeltQuote? _quote;
  CashuMeltResult? _result;
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
    _invoiceController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final factory =
          widget.controllerFactory ??
          MobileCashuLightningPayControllerFactory.create;
      final controller = await factory();
      final options = await controller.loadPayOptions();
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
        _errorMessage = 'Lightning pay is unavailable.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay Lightning')),
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
        icon: Icons.bolt_outlined,
        message:
            'No enabled Mint supports Lightning pay. Add or refresh a Mint with NUT-05 and NUT-08 support first.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Card(
          child: ListTile(
            leading: Icon(Icons.warning_amber_rounded),
            title: Text('Lightning payments spend Cashu balance'),
            subtitle: Text(
              'Create a quote first, review the fee reserve, then confirm the payment.',
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
                  _quote = null;
                  _result = null;
                }),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _invoiceController,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Lightning invoice',
            hintText: 'lnbc...',
          ),
          onChanged: (_) => setState(() {
            _quote = null;
            _result = null;
          }),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _mutating ? null : _createQuote,
          icon: _mutating
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.receipt_long_outlined),
          label: const Text('Create payment quote'),
        ),
        if (_quote case final quote?) ...[
          const SizedBox(height: 20),
          _MeltQuoteCard(
            quote: quote,
            result: _result,
            onPay: _mutating || quote.state == CashuQuoteState.paid
                ? null
                : _payQuote,
          ),
        ],
      ],
    );
  }

  Future<void> _createQuote() async {
    final mintUrl = _selectedMintUrl;
    final invoice = _invoiceController.text.trim();
    if (mintUrl == null || invoice.isEmpty) {
      _showError(ArgumentError('Enter a Lightning invoice.'));
      return;
    }

    setState(() => _mutating = true);
    try {
      final quote = await _controller!.createQuote(
        mintUrl: mintUrl,
        bolt11Invoice: invoice,
      );
      if (!mounted) return;
      setState(() {
        _quote = quote;
        _result = null;
      });
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _payQuote() async {
    final quote = _quote;
    if (quote == null) return;

    setState(() => _mutating = true);
    try {
      final result = await _controller!.payQuote(
        mintUrl: quote.mintUrl,
        quoteId: quote.quoteId,
      );
      if (!mounted) return;
      setState(() => _result = result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Paid ${result.amountSpent.value} sat, fee ${result.feePaid.value} sat.',
          ),
        ),
      );
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
      UnknownMintException() => 'This Mint is not configured.',
      DisabledMintException() => 'Enable this Mint before paying.',
      UnsupportedMintException() => 'This Mint does not support Lightning pay.',
      InsufficientCashuBalanceException(
        :final availableSats,
        :final requestedSats,
      ) =>
        'Insufficient balance: $availableSats sat available, $requestedSats sat requested.',
      WalletNotReadyException() => 'Create or restore a wallet first.',
      ArgumentError() => 'Enter a Lightning invoice.',
      _ => 'Lightning payment failed. Please try again.',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

final class _MeltQuoteCard extends StatelessWidget {
  const _MeltQuoteCard({
    required this.quote,
    required this.result,
    required this.onPay,
  });

  final CashuMeltQuote quote;
  final CashuMeltResult? result;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final totalReserve = quote.amount.value + quote.feeReserve.value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bolt),
              title: Text('${quote.amount.value} sat'),
              subtitle: Text(
                'Fee reserve: ${quote.feeReserve.value} sat\n'
                'Maximum spend: $totalReserve sat\n'
                'Status: ${_quoteStateLabel(quote.state)}\n'
                'Expires: ${quote.expiry.toLocal()}',
              ),
            ),
            if (result case final paid?) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Payment complete'),
                subtitle: Text(
                  'Spent: ${paid.amountSpent.value} sat\n'
                  'Fee paid: ${paid.feePaid.value} sat',
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onPay,
              icon: const Icon(Icons.payment),
              label: const Text('Pay invoice'),
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
