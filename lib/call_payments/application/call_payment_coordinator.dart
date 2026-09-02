import 'dart:async';
import 'dart:math' as math;

import 'package:noscall/call/calling_controller_dependencies.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';

import '../domain/call_payment_models.dart';
import '../domain/call_payment_repositories.dart';
import 'call_payment_outgoing_refund_service.dart';
import 'call_payment_top_up_service.dart';

typedef CallPaymentLifecycleClock = DateTime Function();
typedef CallPaymentTopUpCallback =
    Future<CallPaymentTopUpResult> Function(CallPaymentTopUpRequest request);
typedef CallPaymentOutgoingRefundCallback =
    Future<CallPaymentOutgoingRefundResult> Function(
      CallPaymentOutgoingRefundRequest request,
    );
typedef CallPaymentStopCallCallback =
    Future<void> Function({
      required String callId,
      required CallEndReason reason,
    });

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
    CallPaymentOutgoingRefundCallback? prepareRefund,
    CallPaymentStopCallCallback? stopCall,
    CallPaymentLifecycleScheduler scheduler =
        const TimerCallPaymentLifecycleScheduler(),
    int topUpLeadSeconds = 10,
    CallPaymentLifecycleClock? clock,
  }) : _owner = owner,
       _sessionRepository = sessionRepository,
       _installmentRepository = installmentRepository,
       _prepareTopUp = prepareTopUp,
       _prepareRefund = prepareRefund,
       _stopCall = stopCall,
       _scheduler = scheduler,
       _topUpLeadSeconds = topUpLeadSeconds,
       _clock = clock ?? DateTime.now;

  final CashuAccountId _owner;
  final CallPaymentSessionRepository _sessionRepository;
  final CallPaymentInstallmentRepository _installmentRepository;
  final CallPaymentTopUpCallback? _prepareTopUp;
  final CallPaymentOutgoingRefundCallback? _prepareRefund;
  final CallPaymentStopCallCallback? _stopCall;
  final CallPaymentLifecycleScheduler _scheduler;
  final int _topUpLeadSeconds;
  final CallPaymentLifecycleClock _clock;
  Object? _topUpHandle;
  Object? _paymentStopHandle;

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
    _cancelScheduledPaymentStop();
    final now = _clock();
    final connectedDurationSeconds = _connectedDurationSeconds(session, now);
    final status = await _endedStatus(
      session: session,
      reason: reason,
      hasConnected: hasConnected,
      connectedDurationSeconds: connectedDurationSeconds,
    );
    final updatedSession = session.copyWith(
      status: status,
      endedAt: now,
      connectedDurationSeconds: connectedDurationSeconds,
      updatedAt: now,
    );
    await _sessionRepository.save(updatedSession);
    await _runRefundIfNeeded(updatedSession);
  }

  Future<void> _runRefundIfNeeded(CallPaymentSession session) async {
    final prepareRefund = _prepareRefund;
    if (prepareRefund == null ||
        session.role != CallPaymentRole.payee ||
        session.status != CallPaymentSessionStatus.refundPending) {
      return;
    }
    try {
      await prepareRefund(
        CallPaymentOutgoingRefundRequest(owner: _owner, callId: session.callId),
      );
    } catch (_) {
      // Lifecycle cleanup must not prevent the call controller from finishing.
    }
  }

  Future<CallPaymentSessionStatus> _endedStatus({
    required CallPaymentSession session,
    required CallEndReason reason,
    required bool hasConnected,
    required int connectedDurationSeconds,
  }) async {
    if (hasConnected || session.connectedAt != null) {
      if (await _hasUnusedClaimedPayment(
        session,
        connectedDurationSeconds: connectedDurationSeconds,
      )) {
        return CallPaymentSessionStatus.refundPending;
      }
      if (session.role == CallPaymentRole.payer &&
          await _hasRecoverableSentPayment(session)) {
        return CallPaymentSessionStatus.reclaimPending;
      }
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

  Future<bool> _hasUnusedClaimedPayment(
    CallPaymentSession session, {
    required int connectedDurationSeconds,
  }) async {
    final expectedDirection = session.role == CallPaymentRole.payer
        ? CallPaymentTransferDirection.sent
        : CallPaymentTransferDirection.received;
    final installments = await _installmentRepository.listForCall(
      owner: session.owner,
      callId: session.callId,
    );
    return installments.any(
      (installment) =>
          installment.purpose != CallPaymentPurpose.refund &&
          installment.direction == expectedDirection &&
          installment.status == CallPaymentInstallmentStatus.claimed &&
          connectedDurationSeconds < installment.coversFromSecond,
    );
  }

  Future<bool> _hasRecoverableSentPayment(CallPaymentSession session) async {
    final installments = await _installmentRepository.listForCall(
      owner: session.owner,
      callId: session.callId,
    );
    return installments.any(
      (installment) =>
          installment.purpose != CallPaymentPurpose.refund &&
          installment.direction == CallPaymentTransferDirection.sent &&
          installment.walletOperationId != null &&
          switch (installment.status) {
            CallPaymentInstallmentStatus.prepared ||
            CallPaymentInstallmentStatus.sent ||
            CallPaymentInstallmentStatus.reclaimable ||
            CallPaymentInstallmentStatus.unknown => true,
            _ => false,
          },
    );
  }

  int _connectedDurationSeconds(CallPaymentSession session, DateTime endedAt) {
    final connectedAt = session.connectedAt;
    if (connectedAt == null) return session.connectedDurationSeconds;
    return math.max(
      session.connectedDurationSeconds,
      endedAt.difference(connectedAt).inSeconds,
    );
  }

  void _scheduleTopUp(CallPaymentSession session, {int? paidCoverageToSecond}) {
    if (_prepareTopUp == null || session.role != CallPaymentRole.payer) return;
    _cancelTopUp();
    final delaySeconds = _topUpDelaySeconds(
      session,
      paidCoverageToSecond: paidCoverageToSecond,
    );
    _topUpHandle = _scheduler.schedule(
      Duration(seconds: delaySeconds),
      () => _runTopUp(session.callId),
    );
  }

  int _topUpDelaySeconds(
    CallPaymentSession session, {
    required int? paidCoverageToSecond,
  }) {
    if (paidCoverageToSecond == null || session.connectedAt == null) {
      return math.max(0, session.billingPeriodSeconds - _topUpLeadSeconds);
    }
    final connectedDurationSeconds = _connectedDurationSeconds(
      session,
      _clock(),
    );
    return math.max(
      0,
      paidCoverageToSecond - _topUpLeadSeconds - connectedDurationSeconds,
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
        _scheduleTopUp(
          result.session,
          paidCoverageToSecond: result.installment.coversToSecond,
        );
      } else {
        _schedulePaymentStop(callId);
      }
    } catch (_) {
      _topUpHandle = null;
      _schedulePaymentStop(callId);
    }
  }

  void _schedulePaymentStop(String callId) {
    _cancelScheduledPaymentStop();
    final delaySeconds = math.max(0, _topUpLeadSeconds);
    _paymentStopHandle = _scheduler.schedule(
      Duration(seconds: delaySeconds),
      () async {
        _paymentStopHandle = null;
        await _stopCallBecausePaymentStopped(callId);
      },
    );
  }

  Future<void> _stopCallBecausePaymentStopped(String callId) async {
    final stopCall = _stopCall;
    if (stopCall == null) return;
    try {
      await stopCall(callId: callId, reason: CallEndReason.paymentRequired);
    } catch (_) {
      // Payment bookkeeping should not throw back into the scheduler.
    }
  }

  void _cancelTopUp() {
    final handle = _topUpHandle;
    if (handle == null) return;
    _scheduler.cancel(handle);
    _topUpHandle = null;
  }

  void _cancelScheduledPaymentStop() {
    final handle = _paymentStopHandle;
    if (handle == null) return;
    _scheduler.cancel(handle);
    _paymentStopHandle = null;
  }
}
