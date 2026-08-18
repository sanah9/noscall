import 'package:flutter/material.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/infrastructure/isar_call_payment_repository.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/common/database/db_isar.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';

typedef CallPaymentDetailsLoader =
    Future<CallPaymentDetailsData?> Function(
      CashuAccountId owner,
      String callId,
    );

final class CallPaymentDetailsArguments {
  const CallPaymentDetailsArguments({
    required this.callId,
    this.accountId,
    this.peerDisplayName,
  });

  final String callId;
  final CashuAccountId? accountId;
  final String? peerDisplayName;
}

final class CallPaymentDetailsData {
  const CallPaymentDetailsData({
    required this.session,
    required this.installments,
  });

  final CallPaymentSession session;
  final List<CallPaymentInstallment> installments;
}

final class CallPaymentDetailsPage extends StatefulWidget {
  const CallPaymentDetailsPage({
    super.key,
    required this.arguments,
    this.loader,
  });

  final CallPaymentDetailsArguments arguments;
  final CallPaymentDetailsLoader? loader;

  @override
  State<CallPaymentDetailsPage> createState() => _CallPaymentDetailsPageState();
}

final class _CallPaymentDetailsPageState extends State<CallPaymentDetailsPage> {
  late Future<CallPaymentDetailsData?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<CallPaymentDetailsData?> _load() {
    final owner =
        widget.arguments.accountId ??
        CashuAccountId.fromNostrPubkey(Account.sharedInstance.currentPubkey);
    final loader = widget.loader ?? _defaultLoad;
    return loader(owner, widget.arguments.callId);
  }

  Future<CallPaymentDetailsData?> _defaultLoad(
    CashuAccountId owner,
    String callId,
  ) async {
    final isar = DBISAR.sharedInstance.isar;
    final sessionRepository = IsarCallPaymentSessionRepository(isar);
    final installmentRepository = IsarCallPaymentInstallmentRepository(isar);
    final session = await sessionRepository.find(owner, callId);
    if (session == null) return null;
    final installments = await installmentRepository.listForCall(
      owner: owner,
      callId: callId,
    );
    return CallPaymentDetailsData(session: session, installments: installments);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paid Call Details')),
      body: SafeArea(
        child: FutureBuilder<CallPaymentDetailsData?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const _MessageState(
                icon: Icons.error_outline,
                title: 'Payment details unavailable',
                subtitle: 'Please try again later.',
              );
            }
            final data = snapshot.data;
            if (data == null) {
              return const _MessageState(
                icon: Icons.receipt_long_outlined,
                title: 'No paid call payment found',
                subtitle: 'This call may have been free or not yet synced.',
              );
            }
            return _DetailsList(data: data);
          },
        ),
      ),
    );
  }
}

final class _DetailsList extends StatelessWidget {
  const _DetailsList({required this.data});

  final CallPaymentDetailsData data;

  @override
  Widget build(BuildContext context) {
    final session = data.session;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _SummaryCard(session: session),
        const SizedBox(height: 12),
        _InstallmentsCard(installments: data.installments),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Ordinary token payment'),
            subtitle: Text(
              'Payments use encrypted ordinary Cashu tokens in this release. Refund and reclaim states depend on wallet and peer event recovery.',
            ),
          ),
        ),
      ],
    );
  }
}

final class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.session});

  final CallPaymentSession session;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.paid_outlined),
            title: Text('${session.netSats} sat net'),
            subtitle: Text(_sessionStatusLabel(session.status)),
          ),
          const Divider(height: 1),
          _DetailRow(
            icon: Icons.call_outlined,
            label: 'Call',
            value: _callTypeLabel(session.callType),
          ),
          _DetailRow(
            icon: Icons.payments_outlined,
            label: 'Charged',
            value: '${session.chargedSats} sat',
          ),
          _DetailRow(
            icon: Icons.undo_outlined,
            label: 'Refunded',
            value: '${session.refundedSats} sat',
          ),
          _DetailRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Max spend',
            value: '${session.maxSpendSats} sat',
          ),
          _DetailRow(
            icon: Icons.schedule_outlined,
            label: 'Duration',
            value: '${session.connectedDurationSeconds}s',
          ),
          _DetailRow(
            icon: Icons.hub_outlined,
            label: 'Mint',
            value: session.mintUrl.toString(),
          ),
        ],
      ),
    );
  }
}

final class _InstallmentsCard extends StatelessWidget {
  const _InstallmentsCard({required this.installments});

  final List<CallPaymentInstallment> installments;

  @override
  Widget build(BuildContext context) {
    if (installments.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.receipt_long_outlined),
          title: Text('No payment installments'),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.receipt_long_outlined),
            title: Text('Payment installments'),
          ),
          const Divider(height: 1),
          ...installments.map(
            (installment) => _InstallmentTile(installment: installment),
          ),
        ],
      ),
    );
  }
}

final class _InstallmentTile extends StatelessWidget {
  const _InstallmentTile({required this.installment});

  final CallPaymentInstallment installment;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(_purposeIcon(installment.purpose)),
      title: Text(
        '${_purposeLabel(installment.purpose)} #${installment.sequence}',
      ),
      subtitle: Text(_installmentStatusLabel(installment.status)),
      trailing: Text('${installment.amountSats} sat'),
    );
  }
}

final class _DetailRow extends StatelessWidget {
  const _DetailRow({
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

final class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _callTypeLabel(CallPaymentCallType type) {
  return switch (type) {
    CallPaymentCallType.audio => 'Audio',
    CallPaymentCallType.video => 'Video',
  };
}

String _sessionStatusLabel(CallPaymentSessionStatus status) {
  return switch (status) {
    CallPaymentSessionStatus.reclaimPending => 'Reclaim pending',
    CallPaymentSessionStatus.refundPending => 'Refund pending',
    CallPaymentSessionStatus.completed => 'Completed',
    CallPaymentSessionStatus.paymentFailed => 'Payment failed',
    CallPaymentSessionStatus.insufficientBalance => 'Insufficient balance',
    CallPaymentSessionStatus.noCommonMint => 'No shared Mint',
    CallPaymentSessionStatus.rejected => 'Rejected',
    CallPaymentSessionStatus.timeout => 'Timed out',
    CallPaymentSessionStatus.disputed => 'Disputed',
    _ => status.name,
  };
}

String _installmentStatusLabel(CallPaymentInstallmentStatus status) {
  return switch (status) {
    CallPaymentInstallmentStatus.reclaimable => 'Reclaimable',
    CallPaymentInstallmentStatus.reclaimed => 'Reclaimed',
    CallPaymentInstallmentStatus.refunded => 'Refunded',
    CallPaymentInstallmentStatus.failed => 'Failed',
    CallPaymentInstallmentStatus.unknown => 'Unknown',
    _ => status.name,
  };
}

String _purposeLabel(CallPaymentPurpose purpose) {
  return switch (purpose) {
    CallPaymentPurpose.initial => 'Initial',
    CallPaymentPurpose.topUp => 'Top up',
    CallPaymentPurpose.refund => 'Refund',
  };
}

IconData _purposeIcon(CallPaymentPurpose purpose) {
  return switch (purpose) {
    CallPaymentPurpose.initial => Icons.play_arrow_outlined,
    CallPaymentPurpose.topUp => Icons.add_circle_outline,
    CallPaymentPurpose.refund => Icons.undo_outlined,
  };
}
