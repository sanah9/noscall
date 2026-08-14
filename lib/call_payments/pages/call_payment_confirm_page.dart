import 'package:flutter/material.dart';
import 'package:noscall/call_payments/application/call_payment_start_guard.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

final class CallPaymentConfirmArguments {
  const CallPaymentConfirmArguments({
    required this.peerPubkey,
    required this.callType,
    required this.mintUrl,
    required this.balanceSats,
    required this.priceSatsPerMinute,
    required this.periodAmountSats,
    required this.billingPeriodSeconds,
    required this.gracePeriodSeconds,
    required this.defaultMaxSpendSats,
    this.peerDisplayName,
  });

  factory CallPaymentConfirmArguments.fromDecision(
    CallPaymentStartDecision decision, {
    String? peerDisplayName,
  }) {
    final quote = decision.quote;
    final mintUrl = decision.mintUrl;
    if (quote == null || mintUrl == null) {
      throw ArgumentError('Paid call confirmation requires a paid decision');
    }
    return CallPaymentConfirmArguments(
      peerPubkey: decision.peerPubkey,
      peerDisplayName: peerDisplayName,
      callType: decision.callType,
      mintUrl: mintUrl,
      balanceSats: decision.balanceSats,
      priceSatsPerMinute: quote.priceSatsPerMinute,
      periodAmountSats: quote.periodAmountSats,
      billingPeriodSeconds: quote.billingPeriodSeconds,
      gracePeriodSeconds: quote.gracePeriodSeconds,
      defaultMaxSpendSats: decision.maxSpendSats,
    );
  }

  final String peerPubkey;
  final String? peerDisplayName;
  final CallPaymentCallType callType;
  final CashuMintUrl mintUrl;
  final int balanceSats;
  final int priceSatsPerMinute;
  final int periodAmountSats;
  final int billingPeriodSeconds;
  final int gracePeriodSeconds;
  final int defaultMaxSpendSats;
}

final class CallPaymentConfirmResult {
  const CallPaymentConfirmResult({required this.maxSpendSats});

  final int maxSpendSats;
}

final class CallPaymentConfirmPage extends StatefulWidget {
  const CallPaymentConfirmPage({super.key, required this.arguments});

  final CallPaymentConfirmArguments arguments;

  @override
  State<CallPaymentConfirmPage> createState() => _CallPaymentConfirmPageState();
}

final class _CallPaymentConfirmPageState extends State<CallPaymentConfirmPage> {
  final TextEditingController _maxSpendController = TextEditingController();
  String? _maxSpendError;

  @override
  void initState() {
    super.initState();
    _maxSpendController.text = widget.arguments.defaultMaxSpendSats.toString();
  }

  @override
  void dispose() {
    _maxSpendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.arguments;
    return Scaffold(
      appBar: AppBar(title: const Text('Paid Call')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _CallPaymentSummaryCard(arguments: args),
            const SizedBox(height: 12),
            _buildMaxSpendCard(args),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Ordinary token payment'),
                subtitle: Text(
                  'This first release uses encrypted ordinary Cashu tokens. Tokens are not locked to the receiver and refunds depend on the other client.',
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _confirm,
              icon: const Icon(Icons.call_outlined),
              label: const Text('Confirm and call'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaxSpendCard(CallPaymentConfirmArguments args) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending limit',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _maxSpendController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Maximum spend',
                suffixText: 'sat',
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                border: const OutlineInputBorder(),
                errorText: _maxSpendError,
                helperText:
                    'Balance ${args.balanceSats} sat, minimum ${args.periodAmountSats} sat.',
              ),
              onChanged: (_) {
                if (_maxSpendError != null) {
                  setState(() => _maxSpendError = null);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirm() {
    final args = widget.arguments;
    final value = int.tryParse(_maxSpendController.text.trim());
    if (value == null) {
      setState(() => _maxSpendError = 'Enter a whole sat amount.');
      return;
    }
    if (value < args.periodAmountSats) {
      setState(() => _maxSpendError = 'At least one period is required.');
      return;
    }
    if (value > args.balanceSats) {
      setState(() => _maxSpendError = 'Limit cannot exceed Mint balance.');
      return;
    }
    Navigator.of(context).pop(CallPaymentConfirmResult(maxSpendSats: value));
  }
}

final class _CallPaymentSummaryCard extends StatelessWidget {
  const _CallPaymentSummaryCard({required this.arguments});

  final CallPaymentConfirmArguments arguments;

  @override
  Widget build(BuildContext context) {
    final typeLabel = switch (arguments.callType) {
      CallPaymentCallType.audio => 'Audio',
      CallPaymentCallType.video => 'Video',
    };
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              arguments.callType == CallPaymentCallType.video
                  ? Icons.videocam_outlined
                  : Icons.call_outlined,
            ),
            title: Text(arguments.peerDisplayName ?? arguments.peerPubkey),
            subtitle: Text('$typeLabel call'),
          ),
          const Divider(height: 1),
          _SummaryRow(
            icon: Icons.payments_outlined,
            label: 'Price',
            value: '${arguments.priceSatsPerMinute} sat/min',
          ),
          _SummaryRow(
            icon: Icons.schedule_outlined,
            label: 'First period',
            value:
                '${arguments.periodAmountSats} sat for ${arguments.billingPeriodSeconds}s',
          ),
          _SummaryRow(
            icon: Icons.timer_outlined,
            label: 'Grace',
            value: '${arguments.gracePeriodSeconds}s',
          ),
          _SummaryRow(
            icon: Icons.hub_outlined,
            label: 'Mint',
            value: arguments.mintUrl.toString(),
          ),
        ],
      ),
    );
  }
}

final class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
