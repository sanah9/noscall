import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/call_payments/application/call_payment_coordinator.dart';
import 'package:noscall/call_payments/application/call_payment_outgoing_refund_service.dart';
import 'package:noscall/call_payments/application/call_payment_top_up_service.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/domain/call_payment_repositories.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  test('marks a paid session connected', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    await sessionRepository.save(_session());
    final coordinator = _coordinator(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      times: [DateTime.utc(2026, 8, 14, 10)],
    );

    await coordinator.onConnected(
      callId: 'call-1',
      peerPubkey: _peerPubkey,
      role: CallingRole.caller,
    );

    final session = await sessionRepository.find(_owner, 'call-1');
    expect(session?.status, CallPaymentSessionStatus.connected);
    expect(session?.connectedAt, DateTime.utc(2026, 8, 14, 10));
  });

  test('schedules payer top-up before paid coverage expires', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    final scheduler = _Scheduler();
    await sessionRepository.save(_session());
    final topUpRequests = <CallPaymentTopUpRequest>[];
    final coordinator = _coordinator(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      scheduler: scheduler,
      prepareTopUp: (request) async {
        topUpRequests.add(request);
        return CallPaymentTopUpResult(
          session: (await sessionRepository.find(_owner, request.callId))!,
          installment: _installment(
            status: CallPaymentInstallmentStatus.sent,
            purpose: CallPaymentPurpose.topUp,
            coversFromSecond: 60,
            coversToSecond: 120,
          ),
          okEvent: OKEvent('top-up', true, 'ok'),
        );
      },
      times: [
        DateTime.utc(2026, 8, 14, 10),
        DateTime.utc(2026, 8, 14, 10, 0, 50),
      ],
    );

    await coordinator.onConnected(
      callId: 'call-1',
      peerPubkey: _peerPubkey,
      role: CallingRole.caller,
    );
    expect(scheduler.delays, [const Duration(seconds: 50)]);

    await scheduler.fire(0);

    expect(topUpRequests.single.callId, 'call-1');
    expect(topUpRequests.single.owner, _owner);
    expect(scheduler.delays, [
      const Duration(seconds: 50),
      const Duration(seconds: 60),
    ]);
  });

  test('cancels scheduled top-up when paid call ends', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    final scheduler = _Scheduler();
    await sessionRepository.save(
      _session(
        status: CallPaymentSessionStatus.connected,
        connectedAt: DateTime.utc(2026, 8, 14, 10),
      ),
    );
    final coordinator = _coordinator(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      scheduler: scheduler,
      prepareTopUp: (request) async {
        throw StateError('top-up should be cancelled');
      },
      times: [
        DateTime.utc(2026, 8, 14, 10),
        DateTime.utc(2026, 8, 14, 10, 0, 5),
      ],
    );

    await coordinator.onConnected(
      callId: 'call-1',
      peerPubkey: _peerPubkey,
      role: CallingRole.caller,
    );
    await coordinator.onEnded(
      callId: 'call-1',
      peerPubkey: _peerPubkey,
      role: CallingRole.caller,
      reason: CallEndReason.disconnect,
      hasConnected: true,
    );

    expect(scheduler.cancelledHandles, [0]);
  });

  test('stops call at paid coverage end when top-up fails', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    final scheduler = _Scheduler();
    final stoppedCalls = <({String callId, CallEndReason reason})>[];
    await sessionRepository.save(_session());
    final coordinator = _coordinator(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      scheduler: scheduler,
      prepareTopUp: (request) async {
        final session = (await sessionRepository.find(
          _owner,
          request.callId,
        ))!.copyWith(status: CallPaymentSessionStatus.paymentFailed);
        return CallPaymentTopUpResult(
          session: session,
          installment: _installment(
            status: CallPaymentInstallmentStatus.failed,
          ),
          okEvent: OKEvent('top-up', false, 'failed'),
        );
      },
      stopCall: ({required callId, required reason}) async {
        stoppedCalls.add((callId: callId, reason: reason));
      },
      times: [DateTime.utc(2026, 8, 14, 10)],
    );

    await coordinator.onConnected(
      callId: 'call-1',
      peerPubkey: _peerPubkey,
      role: CallingRole.caller,
    );
    await scheduler.fire(0);

    expect(stoppedCalls, isEmpty);
    expect(scheduler.delays, [
      const Duration(seconds: 50),
      const Duration(seconds: 10),
    ]);
    await scheduler.fire(1);

    expect(stoppedCalls, [
      (callId: 'call-1', reason: CallEndReason.paymentRequired),
    ]);
  });

  test('stops call at paid coverage end when top-up throws', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    final scheduler = _Scheduler();
    final stoppedCalls = <({String callId, CallEndReason reason})>[];
    await sessionRepository.save(_session());
    final coordinator = _coordinator(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      scheduler: scheduler,
      prepareTopUp: (request) async {
        throw StateError('Payment session max spend reached');
      },
      stopCall: ({required callId, required reason}) async {
        stoppedCalls.add((callId: callId, reason: reason));
      },
      times: [DateTime.utc(2026, 8, 14, 10)],
    );

    await coordinator.onConnected(
      callId: 'call-1',
      peerPubkey: _peerPubkey,
      role: CallingRole.caller,
    );
    await scheduler.fire(0);

    expect(stoppedCalls, isEmpty);
    expect(scheduler.delays, [
      const Duration(seconds: 50),
      const Duration(seconds: 10),
    ]);
    await scheduler.fire(1);

    expect(stoppedCalls, [
      (callId: 'call-1', reason: CallEndReason.paymentRequired),
    ]);
  });

  test('cancels delayed payment stop when paid call ends first', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    final scheduler = _Scheduler();
    final stoppedCalls = <({String callId, CallEndReason reason})>[];
    await sessionRepository.save(
      _session(
        status: CallPaymentSessionStatus.connected,
        connectedAt: DateTime.utc(2026, 8, 14, 10),
      ),
    );
    final coordinator = _coordinator(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      scheduler: scheduler,
      prepareTopUp: (request) async {
        throw StateError('Payment session max spend reached');
      },
      stopCall: ({required callId, required reason}) async {
        stoppedCalls.add((callId: callId, reason: reason));
      },
      times: [
        DateTime.utc(2026, 8, 14, 10),
        DateTime.utc(2026, 8, 14, 10, 0, 59),
      ],
    );

    await coordinator.onConnected(
      callId: 'call-1',
      peerPubkey: _peerPubkey,
      role: CallingRole.caller,
    );
    await scheduler.fire(0);
    await coordinator.onEnded(
      callId: 'call-1',
      peerPubkey: _peerPubkey,
      role: CallingRole.caller,
      reason: CallEndReason.disconnect,
      hasConnected: true,
    );

    expect(scheduler.cancelledHandles, [1]);
    await scheduler.fire(1);
    expect(stoppedCalls, isEmpty);
  });

  test('marks connected sessions completed and records duration', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    await sessionRepository.save(
      _session(
        status: CallPaymentSessionStatus.connected,
        connectedAt: DateTime.utc(2026, 8, 14, 10),
      ),
    );
    final coordinator = _coordinator(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      times: [DateTime.utc(2026, 8, 14, 10, 1, 8)],
    );

    await coordinator.onEnded(
      callId: 'call-1',
      peerPubkey: _peerPubkey,
      role: CallingRole.caller,
      reason: CallEndReason.disconnect,
      hasConnected: true,
    );

    final session = await sessionRepository.find(_owner, 'call-1');
    expect(session?.status, CallPaymentSessionStatus.completed);
    expect(session?.endedAt, DateTime.utc(2026, 8, 14, 10, 1, 8));
    expect(session?.connectedDurationSeconds, 68);
  });

  test('moves payer to refund pending when claimed top-up is unused', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    await sessionRepository.save(
      _session(
        status: CallPaymentSessionStatus.connected,
        connectedAt: DateTime.utc(2026, 8, 14, 10),
      ),
    );
    await installmentRepository.save(
      _installment(
        status: CallPaymentInstallmentStatus.claimed,
        purpose: CallPaymentPurpose.topUp,
        coversFromSecond: 60,
        coversToSecond: 120,
      ),
    );
    final coordinator = _coordinator(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      times: [DateTime.utc(2026, 8, 14, 10, 0, 55)],
    );

    await coordinator.onEnded(
      callId: 'call-1',
      peerPubkey: _peerPubkey,
      role: CallingRole.caller,
      reason: CallEndReason.disconnect,
      hasConnected: true,
    );

    final session = await sessionRepository.find(_owner, 'call-1');
    expect(session?.status, CallPaymentSessionStatus.refundPending);
    expect(session?.connectedDurationSeconds, 55);
  });

  test(
    'moves payer to reclaim pending when sent top-up is unclaimed at end',
    () async {
      final sessionRepository = _SessionRepository();
      final installmentRepository = _InstallmentRepository();
      await sessionRepository.save(
        _session(
          status: CallPaymentSessionStatus.connected,
          connectedAt: DateTime.utc(2026, 8, 14, 10),
        ),
      );
      await installmentRepository.save(
        _installment(
          status: CallPaymentInstallmentStatus.sent,
          purpose: CallPaymentPurpose.topUp,
          coversFromSecond: 60,
          coversToSecond: 120,
        ),
      );
      final coordinator = _coordinator(
        sessionRepository: sessionRepository,
        installmentRepository: installmentRepository,
        times: [DateTime.utc(2026, 8, 14, 10, 0, 55)],
      );

      await coordinator.onEnded(
        callId: 'call-1',
        peerPubkey: _peerPubkey,
        role: CallingRole.caller,
        reason: CallEndReason.disconnect,
        hasConnected: true,
      );

      final session = await sessionRepository.find(_owner, 'call-1');
      expect(session?.status, CallPaymentSessionStatus.reclaimPending);
      expect(session?.connectedDurationSeconds, 55);
    },
  );

  test(
    'refunds unused claimed incoming top-up when connected call ends early',
    () async {
      final sessionRepository = _SessionRepository();
      final installmentRepository = _InstallmentRepository();
      await sessionRepository.save(
        _session(
          status: CallPaymentSessionStatus.connected,
          direction: CallPaymentCallDirection.incoming,
          role: CallPaymentRole.payee,
          connectedAt: DateTime.utc(2026, 8, 14, 10),
        ),
      );
      await installmentRepository.save(
        _installment(
          status: CallPaymentInstallmentStatus.claimed,
          direction: CallPaymentTransferDirection.received,
          purpose: CallPaymentPurpose.topUp,
          coversFromSecond: 60,
          coversToSecond: 120,
        ),
      );
      final refundRequests = <CallPaymentOutgoingRefundRequest>[];
      final coordinator = _coordinator(
        sessionRepository: sessionRepository,
        installmentRepository: installmentRepository,
        prepareRefund: (request) async {
          refundRequests.add(request);
          return CallPaymentOutgoingRefundResult(
            session: (await sessionRepository.find(_owner, request.callId))!,
            installments: const [],
          );
        },
        times: [DateTime.utc(2026, 8, 14, 10, 0, 55)],
      );

      await coordinator.onEnded(
        callId: 'call-1',
        peerPubkey: _peerPubkey,
        role: CallingRole.callee,
        reason: CallEndReason.disconnect,
        hasConnected: true,
      );

      final session = await sessionRepository.find(_owner, 'call-1');
      expect(session?.status, CallPaymentSessionStatus.refundPending);
      expect(refundRequests.single.callId, 'call-1');
    },
  );

  test(
    'marks unclaimed outgoing payments reclaim pending before connect',
    () async {
      final sessionRepository = _SessionRepository();
      final installmentRepository = _InstallmentRepository();
      await sessionRepository.save(_session());
      await installmentRepository.save(
        _installment(status: CallPaymentInstallmentStatus.sent),
      );
      final coordinator = _coordinator(
        sessionRepository: sessionRepository,
        installmentRepository: installmentRepository,
        times: [DateTime.utc(2026, 8, 14, 10)],
      );

      await coordinator.onEnded(
        callId: 'call-1',
        peerPubkey: _peerPubkey,
        role: CallingRole.caller,
        reason: CallEndReason.hangup,
        hasConnected: false,
      );

      final session = await sessionRepository.find(_owner, 'call-1');
      expect(session?.status, CallPaymentSessionStatus.reclaimPending);
    },
  );

  test('marks claimed payments refund pending before connect', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    await sessionRepository.save(_session());
    await installmentRepository.save(
      _installment(status: CallPaymentInstallmentStatus.claimed),
    );
    final coordinator = _coordinator(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      times: [DateTime.utc(2026, 8, 14, 10)],
    );

    await coordinator.onEnded(
      callId: 'call-1',
      peerPubkey: _peerPubkey,
      role: CallingRole.caller,
      reason: CallEndReason.reject,
      hasConnected: false,
    );

    final session = await sessionRepository.find(_owner, 'call-1');
    expect(session?.status, CallPaymentSessionStatus.refundPending);
  });

  test(
    'starts payee refund when claimed incoming payment never connects',
    () async {
      final sessionRepository = _SessionRepository();
      final installmentRepository = _InstallmentRepository();
      await sessionRepository.save(
        _session(
          direction: CallPaymentCallDirection.incoming,
          role: CallPaymentRole.payee,
        ),
      );
      await installmentRepository.save(
        _installment(
          status: CallPaymentInstallmentStatus.claimed,
          direction: CallPaymentTransferDirection.received,
        ),
      );
      final refundRequests = <CallPaymentOutgoingRefundRequest>[];
      final coordinator = _coordinator(
        sessionRepository: sessionRepository,
        installmentRepository: installmentRepository,
        prepareRefund: (request) async {
          refundRequests.add(request);
          return CallPaymentOutgoingRefundResult(
            session: (await sessionRepository.find(_owner, request.callId))!,
            installments: const [],
          );
        },
        times: [DateTime.utc(2026, 8, 14, 10)],
      );

      await coordinator.onEnded(
        callId: 'call-1',
        peerPubkey: _peerPubkey,
        role: CallingRole.callee,
        reason: CallEndReason.reject,
        hasConnected: false,
      );

      expect(refundRequests.single.owner, _owner);
      expect(refundRequests.single.callId, 'call-1');
    },
  );

  test('ignores lifecycle events for unknown payment sessions', () async {
    final sessionRepository = _SessionRepository();
    final coordinator = _coordinator(
      sessionRepository: sessionRepository,
      installmentRepository: _InstallmentRepository(),
      times: [DateTime.utc(2026, 8, 14, 10)],
    );

    await coordinator.onConnected(
      callId: 'missing-call',
      peerPubkey: _peerPubkey,
      role: CallingRole.caller,
    );

    expect(await sessionRepository.list(_owner), isEmpty);
  });
}

final _owner = CashuAccountId.fromNostrPubkey('a' * 64);
const _peerPubkey =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
final _mintUrl = CashuMintUrl.parse('https://mint.example');

CallPaymentCoordinator _coordinator({
  required _SessionRepository sessionRepository,
  required _InstallmentRepository installmentRepository,
  required List<DateTime> times,
  _Scheduler? scheduler,
  CallPaymentTopUpCallback? prepareTopUp,
  CallPaymentOutgoingRefundCallback? prepareRefund,
  CallPaymentStopCallCallback? stopCall,
}) {
  var index = 0;
  return CallPaymentCoordinator(
    owner: _owner,
    sessionRepository: sessionRepository,
    installmentRepository: installmentRepository,
    scheduler: scheduler ?? _Scheduler(),
    prepareTopUp: prepareTopUp,
    prepareRefund: prepareRefund,
    stopCall: stopCall,
    clock: () => times[index++ < times.length ? index - 1 : times.length - 1],
  );
}

CallPaymentSession _session({
  CallPaymentSessionStatus status = CallPaymentSessionStatus.ringing,
  CallPaymentCallDirection direction = CallPaymentCallDirection.outgoing,
  CallPaymentRole role = CallPaymentRole.payer,
  DateTime? connectedAt,
}) {
  final now = DateTime.utc(2026, 8, 14, 9);
  return CallPaymentSession(
    owner: _owner,
    callId: 'call-1',
    peerPubkey: _peerPubkey,
    direction: direction,
    role: role,
    callType: CallPaymentCallType.audio,
    status: status,
    mintUrl: _mintUrl,
    priceSatsPerMinute: 10,
    billingPeriodSeconds: 60,
    maxSpendSats: 100,
    connectedAt: connectedAt,
    connectedDurationSeconds: 0,
    chargedSats: 10,
    refundedSats: 0,
    createdAt: now,
    updatedAt: now,
  );
}

CallPaymentInstallment _installment({
  required CallPaymentInstallmentStatus status,
  CallPaymentTransferDirection direction = CallPaymentTransferDirection.sent,
  CallPaymentPurpose purpose = CallPaymentPurpose.initial,
  int coversFromSecond = 0,
  int coversToSecond = 60,
}) {
  final now = DateTime.utc(2026, 8, 14, 9);
  return CallPaymentInstallment(
    owner: _owner,
    callId: 'call-1',
    paymentSessionId: 'payment-session-1',
    sequence: 1,
    purpose: purpose,
    direction: direction,
    amountSats: 10,
    mintUrl: _mintUrl,
    walletOperationId: 'send-op-1',
    tokenHash: 'hash-1',
    status: status,
    coversFromSecond: coversFromSecond,
    coversToSecond: coversToSecond,
    createdAt: now,
    updatedAt: now,
  );
}

final class _SessionRepository implements CallPaymentSessionRepository {
  final Map<String, CallPaymentSession> sessions = {};

  @override
  Future<CallPaymentSession?> find(CashuAccountId owner, String callId) async {
    return sessions['${owner.value}|$callId'];
  }

  @override
  Future<List<CallPaymentSession>> list(CashuAccountId owner) async {
    return sessions.values
        .where((session) => session.owner == owner)
        .toList(growable: false);
  }

  @override
  Future<void> save(CallPaymentSession session) async {
    sessions['${session.owner.value}|${session.callId}'] = session;
  }
}

final class _InstallmentRepository implements CallPaymentInstallmentRepository {
  final Map<String, CallPaymentInstallment> installments = {};

  @override
  Future<CallPaymentInstallment?> find({
    required CashuAccountId owner,
    required String callId,
    required int sequence,
    required CallPaymentPurpose purpose,
    required CallPaymentTransferDirection direction,
  }) async {
    return installments[_key(owner, callId, sequence, purpose, direction)];
  }

  @override
  Future<CallPaymentInstallment?> findByWalletOperationId({
    required CashuAccountId owner,
    required String walletOperationId,
  }) async {
    return installments.values
        .where(
          (installment) =>
              installment.owner == owner &&
              installment.walletOperationId == walletOperationId,
        )
        .firstOrNull;
  }

  @override
  Future<List<CallPaymentInstallment>> listForCall({
    required CashuAccountId owner,
    required String callId,
  }) async {
    return installments.values
        .where(
          (installment) =>
              installment.owner == owner && installment.callId == callId,
        )
        .toList(growable: false);
  }

  @override
  Future<void> save(CallPaymentInstallment installment) async {
    installments[_key(
          installment.owner,
          installment.callId,
          installment.sequence,
          installment.purpose,
          installment.direction,
        )] =
        installment;
  }

  String _key(
    CashuAccountId owner,
    String callId,
    int sequence,
    CallPaymentPurpose purpose,
    CallPaymentTransferDirection direction,
  ) {
    return '${owner.value}|$callId|$sequence|${purpose.name}|${direction.name}';
  }
}

final class _Scheduler implements CallPaymentLifecycleScheduler {
  final List<Duration> delays = [];
  final List<Future<void> Function()> callbacks = [];
  final List<Object> cancelledHandles = [];
  final Set<Object> _cancelledHandleSet = {};

  @override
  Object schedule(Duration delay, Future<void> Function() callback) {
    delays.add(delay);
    callbacks.add(callback);
    return callbacks.length - 1;
  }

  @override
  void cancel(Object handle) {
    cancelledHandles.add(handle);
    _cancelledHandleSet.add(handle);
  }

  Future<void> fire(int index) {
    if (_cancelledHandleSet.contains(index)) return Future.value();
    return callbacks[index]();
  }
}
