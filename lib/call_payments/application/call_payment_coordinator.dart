import 'dart:math' as math;

import 'package:noscall/call/calling_controller_dependencies.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';

import '../domain/call_payment_models.dart';
import '../domain/call_payment_repositories.dart';

typedef CallPaymentLifecycleClock = DateTime Function();

final class CallPaymentCoordinator
    implements CallingControllerLifecycleObserver {
  CallPaymentCoordinator({
    required CashuAccountId owner,
    required CallPaymentSessionRepository sessionRepository,
    required CallPaymentInstallmentRepository installmentRepository,
    CallPaymentLifecycleClock? clock,
  }) : _owner = owner,
       _sessionRepository = sessionRepository,
       _installmentRepository = installmentRepository,
       _clock = clock ?? DateTime.now;

  final CashuAccountId _owner;
  final CallPaymentSessionRepository _sessionRepository;
  final CallPaymentInstallmentRepository _installmentRepository;
  final CallPaymentLifecycleClock _clock;

  @override
  Future<void> onConnected({
    required String callId,
    required String peerPubkey,
    required CallingRole role,
  }) async {
    final session = await _sessionRepository.find(_owner, callId);
    if (session == null) return;

    final now = _clock();
    await _sessionRepository.save(
      session.copyWith(
        status: CallPaymentSessionStatus.connected,
        connectedAt: session.connectedAt ?? now,
        updatedAt: now,
      ),
    );
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
}
