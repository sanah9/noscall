import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/call_payments/pages/call_payment_details_page.dart';
import 'package:noscall/core/account/account.dart';
import '../application/wallet_activity_service.dart';
import '../domain/cashu_account_id.dart';

class WalletActivityPage extends StatefulWidget {
  const WalletActivityPage({super.key, this.owner, this.loader});
  final CashuAccountId? owner;
  final WalletActivityLoader? loader;
  @override
  State<WalletActivityPage> createState() => _WalletActivityPageState();
}

class _WalletActivityPageState extends State<WalletActivityPage> {
  late Future<List<WalletActivityEntry>> _future;
  WalletActivityKind? _kind;
  bool _pendingOnly = false;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<WalletActivityEntry>> _load() async {
    final owner =
        widget.owner ??
        CashuAccountId.fromNostrPubkey(Account.sharedInstance.currentPubkey);
    return (widget.loader ?? WalletActivityService.load)(owner);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {
      /* FutureBuilder presents the error. */
    }
  }

  Future<void> _open(WalletActivityEntry entry) async {
    if (entry.callId != null) {
      await context.push(
        '/call-payments/details',
        extra: CallPaymentDetailsArguments(
          callId: entry.callId!,
          accountId: widget.owner,
        ),
      );
    } else {
      final manage = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  entry.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  '${entry.amountSats} sat',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(entry.status),
                const SizedBox(height: 16),
                Text(_dateLabel(context, entry.createdAt)),
                Text(entry.mintUrl.toString()),
                if (entry.detail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(entry.detail),
                  ),
                const SizedBox(height: 16),
                const Text('Record ID'),
                SelectableText(entry.id),
                if (entry.manageRoute != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Manage transactions'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
      if (manage == true && mounted) await context.push(entry.manageRoute!);
    }
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Wallet activity'),
      actions: [
        IconButton(
          onPressed: _refresh,
          tooltip: 'Refresh activity',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<WalletActivityKind?>(
                    value: _kind,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All activity'),
                      ),
                      for (final kind in WalletActivityKind.values)
                        DropdownMenuItem(
                          value: kind,
                          child: Text(switch (kind) {
                            WalletActivityKind.token => 'Tokens',
                            WalletActivityKind.lightning => 'Lightning',
                            WalletActivityKind.call => 'Calls',
                          }),
                        ),
                    ],
                    onChanged: (value) => setState(() => _kind = value),
                  ),
                ),
                const SizedBox(width: 12),
                Checkbox(
                  value: _pendingOnly,
                  onChanged: (value) =>
                      setState(() => _pendingOnly = value ?? false),
                ),
                const Flexible(child: Text('Pending')),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<WalletActivityEntry>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Activity could not be loaded.'),
                        TextButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                final entries = (snapshot.data ?? [])
                    .where(
                      (entry) =>
                          (_kind == null || entry.kind == _kind) &&
                          (!_pendingOnly || entry.pending),
                    )
                    .toList();
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: entries.isEmpty ? 1 : entries.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 56),
                    itemBuilder: (context, index) {
                      if (entries.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: Text('No matching activity')),
                        );
                      }
                      final entry = entries[index];
                      return ListTile(
                        leading: Icon(switch (entry.kind) {
                          WalletActivityKind.call => Icons.call_outlined,
                          WalletActivityKind.lightning => Icons.bolt,
                          WalletActivityKind.token =>
                            entry.incoming
                                ? Icons.south_west
                                : Icons.north_east,
                        }),
                        title: Text(entry.title),
                        subtitle: Text(
                          '${entry.status}\n${_dateLabel(context, entry.createdAt)}',
                        ),
                        trailing: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 100),
                          child: Text(
                            '${entry.amountSats} sat',
                            textAlign: TextAlign.end,
                          ),
                        ),
                        isThreeLine: true,
                        onTap: () => _open(entry),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

String _dateLabel(BuildContext context, DateTime date) {
  final local = date.toLocal();
  final labels = MaterialLocalizations.of(context);
  return '${labels.formatMediumDate(local)} ${labels.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}
