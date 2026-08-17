import 'dart:async';
import 'dart:math' as math;

import 'package:noscall/call/calling_controller_dependencies.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';

import '../domain/call_payment_models.dart';
import '../domain/call_payment_repositories.dart';
import 'call_payment_top_up_service.dart';

typedef CallPaymentLifecycleClock = DateTime Function();
typedef CallPaymentTopUpCallback =
    Future<CallPaymentTopUpResult> Function(CallPaymentTopUpRequest request);

abstract interface class CallPaymentLifecycleScheduler {
  Object schedule(Duration delay, Future<void> Function() callback);

  void cancel(Object handle);
}

final class TimerCallPaymentLifecycleScheduler
    implements CallPaymentLifecycleScheduler {
  const TimerCallPaymentLifecycleScheduler();

  @override
  Object schedule(Duration delay, Future<void> Function() callback) {
    return Timer(delay, () => callback());
  }

  @override
  void cancel(Object handle) {
    if (handle is Timer) handle.cancel();
  }
}

final class CallPaymentCoordinator
    implements CallingControllerLifecycleObserver {
  CallPaymentCoordinator({
    required CashuAccountId owner,
    required CallPaymentSessionRepository sessionRepository,
    required CallPaymentInstallmentRepository installmentRepository,
    CallPaymentTopUpCallback? prepareTopUp,
    CallPaymentLifecycleScheduler scheduler =
        const TimerCallPaymentLifecycleScheduler(),
    int topUpLeadSeconds = 10,
    CallPaymentLifecycleClock? clock,
  }) : _owner = owner,
       _sessionRepository = sessionRepository,
       _installmentRepository = installmentRepository,
       _prepareTopUp = prepareTopUp,
       _scheduler = scheduler,
       _topUpLeadSeconds = topUpLeadSeconds,
       _clock = clock ?? DateTime.now;

  final CashuAccountId _owner;
  final CallPaymentSessionRepository _sessionRepository;
  final CallPaymentInstallmentRepository _installmentRepository;
  final CallPaymentTopUpCallback? _prepareTopUp;
  final CallPaymentLifecycleScheduler _scheduler;
  final int _topUpLeadSeconds;
  final CallPaymentLifecycleClock _clock;
  Object? _topUpHandle;

  @override
  Future<void> onConnected({
    required String callId,
    required String peerPubkey,
    required CallingRole role,
  }) async {
    final session = await _sessionRepository.find(_owner, callId);
    if (session == null) return;

    final now = _clock();
    final updatedSession = session.copyWith(
      status: CallPaymentSessionStatus.connected,
      connectedAt: session.connectedAt ?? now,
      updatedAt: now,
    );
    await _sessionRepository.save(updatedSession);
    _scheduleTopUp(updatedSession);
  }

  @override
  Future<void> onEnded({
    required String callId,
    required String peerPubkey,
    required CallingRole role,
    required CallEndReason reason,
    required bool hasConnected,
  }) async {
    final session = await _sessionRepository.find(_owner, callId);
    if (session == null) return;

    _cancelTopUp();
    final now = _clock();
    final status = await _endedStatus(
      session: session,
      reason: reason,
      hasConnected: hasConnected,
    );
    await _sessionRepository.save(
      session.copyWith(
        status: status,
        endedAt: now,
        connectedDurationSeconds: _connectedDurationSeconds(session, now),
        updatedAt: now,
      ),
    );
  }

  Future<CallPaymentSessionStatus> _endedStatus({
    required CallPaymentSession session,
    required CallEndReason reason,
    required bool hasConnected,
  }) async {
    if (hasConnected || session.connectedAt != null) {
      return CallPaymentSessionStatus.completed;
    }

    final installments = await _installmentRepository.listForCall(
      owner: session.owner,
      callId: session.callId,
    );
    final hasClaimedPayment = installments.any(
      (installment) =>
          installment.status == CallPaymentInstallmentStatus.claimed,
    );

    if (hasClaimedPayment) {
      return CallPaymentSessionStatus.refundPending;
    }
    if (session.role == CallPaymentRole.payer && installments.isNotEmpty) {
      return CallPaymentSessionStatus.reclaimPending;
    }
    return switch (reason) {
      CallEndReason.reject => CallPaymentSessionStatus.rejected,
      CallEndReason.timeout => CallPaymentSessionStatus.timeout,
      _ => CallPaymentSessionStatus.completed,
    };
  }

  int _connectedDurationSeconds(CallPaymentSession session, DateTime endedAt) {
    final connectedAt = session.connectedAt;
    if (connectedAt == null) return session.connectedDurationSeconds;
    return math.max(
      session.connectedDurationSeconds,
      endedAt.difference(connectedAt).inSeconds,
    );
  }

  void _scheduleTopUp(CallPaymentSession session) {
    if (_prepareTopUp == null || session.role != CallPaymentRole.payer) return;
    _cancelTopUp();
    final delaySeconds = math.max(
      0,
      session.billingPeriodSeconds - _topUpLeadSeconds,
    );
    _topUpHandle = _scheduler.schedule(
      Duration(seconds: delaySeconds),
      () => _runTopUp(session.callId),
    );
  }

  Future<void> _runTopUp(String callId) async {
    final prepareTopUp = _prepareTopUp;
    if (prepareTopUp == null) return;
    try {
      final result = await prepareTopUp(
        CallPaymentTopUpRequest(owner: _owner, callId: callId),
      );
      _topUpHandle = null;
      if (result.session.status == CallPaymentSessionStatus.connected) {
        _scheduleTopUp(result.session);
      }
    } catch (_) {
      _topUpHandle = null;
    }
  }

  void _cancelTopUp() {
    final handle = _topUpHandle;
    if (handle == null) return;
    _scheduler.cancel(handle);
    _topUpHandle = null;
  }
}
