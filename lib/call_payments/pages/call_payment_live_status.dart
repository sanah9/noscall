import 'dart:async';
import 'package:flutter/material.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import '../application/call_payment_details.dart';
import '../domain/call_payment_models.dart';

class CallPaymentLiveStatus extends StatefulWidget {
  const CallPaymentLiveStatus({
    super.key,
    required this.callId,
    this.owner,
    this.loader,
  });
  final String callId;
  final CashuAccountId? owner;
  final CallPaymentDetailsLoader? loader;
  @override
  State<CallPaymentLiveStatus> createState() => _CallPaymentLiveStatusState();
}

class _CallPaymentLiveStatusState extends State<CallPaymentLiveStatus> {
  Timer? _timer;
  CallPaymentDetailsData? _data;
  bool _loading = false;
  bool _stale = false;
  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) return;
    _loading = true;
    try {
      final owner =
          widget.owner ??
          CashuAccountId.fromNostrPubkey(Account.sharedInstance.currentPubkey);
      final data = await (widget.loader ?? CallPaymentDetailsData.load)(
        owner,
        widget.callId,
      );
      if (mounted) {
        setState(() {
          _data = data;
          _stale = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _stale = true);
    } finally {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) return const SizedBox.shrink();
    final summary = data.summary;
    final session = data.session;
    final payer = session.role == CallPaymentRole.payer;
    final nearBudget = summary.nearBudget(session);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: nearBudget ? scheme.errorContainer : scheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text(
                      payer
                          ? 'Prepaid ${summary.chargedSats} / ${session.maxSpendSats} sat'
                          : 'Received ${summary.chargedSats} sat',
                    ),
                    Text('${session.priceSatsPerMinute} sat/min'),
                  ],
                ),
                if (summary.reservedSats > 0)
                  Text(
                    '${summary.reservedSats} sat reserved; confirmation pending',
                  ),
                if (nearBudget)
                  Text(
                    summary.committedSats >= session.maxSpendSats
                        ? 'Spending limit reached'
                        : 'Approaching spending limit (80%)',
                  ),
                if (_stale) const Text('Fee status may be out of date'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
