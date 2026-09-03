import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call_payments/application/call_payment_recovery_service.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/domain/call_payment_repositories.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  test(
    'reclaims recoverable sent installments and completes session',
    () async {
      final sessionRepository = _SessionRepository();
      final installmentRepository = _InstallmentRepository();
      final recoverer = _Recoverer(state: CashuSendState.recoverable);
      await sessionRepository.save(_session());
      await installmentRepository.save(_installment());
      final service = _service(
        sessionRepository: sessionRepository,
        installmentRepository: installmentRepository,
        recoverer: recoverer,
      );

      final report = await service.recover(_owner);

      final session = await sessionRepository.find(_owner, 'call-1');
      final installment = await installmentRepository.find(
        owner: _owner,
        callId: 'call-1',
        sequence: 1,
        purpose: CallPaymentPurpose.initial,
        direction: CallPaymentTransferDirection.sent,
      );
      expect(report.reclaimedInstallments, 1);
      expect(recoverer.reclaimedOperationIds, ['op-1']);
      expect(session?.status, CallPaymentSessionStatus.completed);
      expect(session?.refundedSats, 10);
      expect(session?.netSats, 0);
      expect(installment?.status, CallPaymentInstallmentStatus.reclaimed);
    },
  );

  test('caps refunded sats when reclaiming sent installments', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    await sessionRepository.save(_session(chargedSats: 10, refundedSats: 8));
    await installmentRepository.save(_installment());
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      recoverer: _Recoverer(state: CashuSendState.recoverable),
    );

    await service.recover(_owner);

    final session = await sessionRepository.find(_owner, 'call-1');
    expect(session?.refundedSats, 10);
    expect(session?.netSats, 0);
  });

  test('moves claimed sent installments to refund pending', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    await sessionRepository.save(_session());
    await installmentRepository.save(_installment());
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      recoverer: _Recoverer(state: CashuSendState.claimed),
    );

    final report = await service.recover(_owner);

    final session = await sessionRepository.find(_owner, 'call-1');
    final installment = await installmentRepository.find(
      owner: _owner,
      callId: 'call-1',
      sequence: 1,
      purpose: CallPaymentPurpose.initial,
      direction: CallPaymentTransferDirection.sent,
    );
    expect(report.claimedInstallments, 1);
    expect(session?.status, CallPaymentSessionStatus.refundPending);
    expect(installment?.status, CallPaymentInstallmentStatus.claimed);
    expect(installment?.claimedAt, isNotNull);
  });

  test('keeps unknown sent installments reclaim pending', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    await sessionRepository.save(_session());
    await installmentRepository.save(_installment());
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      recoverer: _Recoverer(state: CashuSendState.unknown),
    );

    final report = await service.recover(_owner);

    final session = await sessionRepository.find(_owner, 'call-1');
    final installment = await installmentRepository.find(
      owner: _owner,
      callId: 'call-1',
      sequence: 1,
      purpose: CallPaymentPurpose.initial,
      direction: CallPaymentTransferDirection.sent,
    );
    expect(report.unknownInstallments, 1);
    expect(session?.status, CallPaymentSessionStatus.reclaimPending);
    expect(installment?.status, CallPaymentInstallmentStatus.unknown);
    expect(installment?.errorCode, 'payment_reclaim_status_unknown');
  });

  test(
    'ignores sessions that are not reclaim pending payer sessions',
    () async {
      final sessionRepository = _SessionRepository();
      final installmentRepository = _InstallmentRepository();
      final recoverer = _Recoverer(state: CashuSendState.recoverable);
      await sessionRepository.save(
        _session(status: CallPaymentSessionStatus.completed),
      );
      await installmentRepository.save(_installment());
      final service = _service(
        sessionRepository: sessionRepository,
        installmentRepository: installmentRepository,
        recoverer: recoverer,
      );

      final report = await service.recover(_owner);

      expect(report.scannedSessions, 0);
      expect(recoverer.checkedOperationIds, isEmpty);
    },
  );

  test('does not recover refund installments', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    final recoverer = _Recoverer(state: CashuSendState.recoverable);
    await sessionRepository.save(_session());
    await installmentRepository.save(
      _installment(purpose: CallPaymentPurpose.refund),
    );
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      recoverer: recoverer,
    );

    final report = await service.recover(_owner);

    expect(report.scannedSessions, 1);
    expect(report.reclaimedInstallments, 0);
    expect(recoverer.checkedOperationIds, isEmpty);
  });

  test(
    'expires stale incoming ringing sessions with claimed received payment',
    () async {
      final sessionRepository = _SessionRepository();
      final installmentRepository = _InstallmentRepository();
      await sessionRepository.save(
        _session(
          direction: CallPaymentCallDirection.incoming,
          role: CallPaymentRole.payee,
          status: CallPaymentSessionStatus.ringing,
          updatedAt: DateTime.utc(2026, 8, 14, 9, 58, 59),
        ),
      );
      await installmentRepository.save(
        _installment(
          direction: CallPaymentTransferDirection.received,
          status: CallPaymentInstallmentStatus.claimed,
        ),
      );
      final service = _service(
        sessionRepository: sessionRepository,
        installmentRepository: installmentRepository,
        recoverer: _Recoverer(state: CashuSendState.recoverable),
      );

      final expiredSessions = await service.expireStaleIncomingRingingSessions(
        _owner,
      );

      final session = await sessionRepository.find(_owner, 'call-1');
      expect(expiredSessions, hasLength(1));
      expect(expiredSessions.single.callId, 'call-1');
      expect(session?.status, CallPaymentSessionStatus.refundPending);
      expect(session?.endedAt, DateTime.utc(2026, 8, 14, 10));
      expect(session?.updatedAt, DateTime.utc(2026, 8, 14, 10));
    },
  );

  test(
    'keeps stale incoming ringing sessions with only refund installments',
    () async {
      final sessionRepository = _SessionRepository();
      final installmentRepository = _InstallmentRepository();
      await sessionRepository.save(
        _session(
          direction: CallPaymentCallDirection.incoming,
          role: CallPaymentRole.payee,
          status: CallPaymentSessionStatus.ringing,
          updatedAt: DateTime.utc(2026, 8, 14, 9, 58, 59),
        ),
      );
      await installmentRepository.save(
        _installment(
          purpose: CallPaymentPurpose.refund,
          direction: CallPaymentTransferDirection.received,
          status: CallPaymentInstallmentStatus.claimed,
        ),
      );
      final service = _service(
        sessionRepository: sessionRepository,
        installmentRepository: installmentRepository,
        recoverer: _Recoverer(state: CashuSendState.recoverable),
      );

      final expiredSessions = await service.expireStaleIncomingRingingSessions(
        _owner,
      );

      final session = await sessionRepository.find(_owner, 'call-1');
      expect(expiredSessions, isEmpty);
      expect(session?.status, CallPaymentSessionStatus.ringing);
      expect(session?.endedAt, isNull);
    },
  );

  test(
    'keeps fresh incoming ringing sessions with claimed received payment',
    () async {
      final sessionRepository = _SessionRepository();
      final installmentRepository = _InstallmentRepository();
      await sessionRepository.save(
        _session(
          direction: CallPaymentCallDirection.incoming,
          role: CallPaymentRole.payee,
          status: CallPaymentSessionStatus.ringing,
          updatedAt: DateTime.utc(2026, 8, 14, 9, 59, 1),
        ),
      );
      await installmentRepository.save(
        _installment(
          direction: CallPaymentTransferDirection.received,
          status: CallPaymentInstallmentStatus.claimed,
        ),
      );
      final service = _service(
        sessionRepository: sessionRepository,
        installmentRepository: installmentRepository,
        recoverer: _Recoverer(state: CashuSendState.recoverable),
      );

      final expiredSessions = await service.expireStaleIncomingRingingSessions(
        _owner,
      );

      final session = await sessionRepository.find(_owner, 'call-1');
      expect(expiredSessions, isEmpty);
      expect(session?.status, CallPaymentSessionStatus.ringing);
      expect(session?.endedAt, isNull);
    },
  );

  test(
    'keeps stale incoming ringing sessions without claimed payment',
    () async {
      final sessionRepository = _SessionRepository();
      final installmentRepository = _InstallmentRepository();
      await sessionRepository.save(
        _session(
          direction: CallPaymentCallDirection.incoming,
          role: CallPaymentRole.payee,
          status: CallPaymentSessionStatus.ringing,
          updatedAt: DateTime.utc(2026, 8, 14, 9, 58, 59),
        ),
      );
      await installmentRepository.save(
        _installment(
          direction: CallPaymentTransferDirection.received,
          status: CallPaymentInstallmentStatus.received,
        ),
      );
      final service = _service(
        sessionRepository: sessionRepository,
        installmentRepository: installmentRepository,
        recoverer: _Recoverer(state: CashuSendState.recoverable),
      );

      final expiredSessions = await service.expireStaleIncomingRingingSessions(
        _owner,
      );

      final session = await sessionRepository.find(_owner, 'call-1');
      expect(expiredSessions, isEmpty);
      expect(session?.status, CallPaymentSessionStatus.ringing);
      expect(session?.endedAt, isNull);
    },
  );
}

final _owner = CashuAccountId.fromNostrPubkey('a' * 64);
const _peerPubkey =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
final _mintUrl = CashuMintUrl.parse('https://mint.example');

CallPaymentRecoveryService _service({
  required _SessionRepository sessionRepository,
  required _InstallmentRepository installmentRepository,
  required _Recoverer recoverer,
}) {
  return CallPaymentRecoveryService(
    sessionRepository: sessionRepository,
    installmentRepository: installmentRepository,
    tokenRecoverer: recoverer,
    clock: () => DateTime.utc(2026, 8, 14, 10),
  );
}

CallPaymentSession _session({
  CallPaymentSessionStatus status = CallPaymentSessionStatus.reclaimPending,
  CallPaymentCallDirection direction = CallPaymentCallDirection.outgoing,
  CallPaymentRole role = CallPaymentRole.payer,
  int chargedSats = 10,
  int refundedSats = 0,
  DateTime? updatedAt,
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
    connectedDurationSeconds: 0,
    chargedSats: chargedSats,
    refundedSats: refundedSats,
    createdAt: now,
    updatedAt: updatedAt ?? now,
  );
}

CallPaymentInstallment _installment({
  CallPaymentPurpose purpose = CallPaymentPurpose.initial,
  CallPaymentTransferDirection direction = CallPaymentTransferDirection.sent,
  CallPaymentInstallmentStatus status = CallPaymentInstallmentStatus.sent,
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
    walletOperationId: 'op-1',
    status: status,
    coversFromSecond: 0,
    coversToSecond: 60,
    createdAt: now,
    updatedAt: now,
  );
}

final class _Recoverer implements CallPaymentTokenRecoverer {
  _Recoverer({required this.state});

  final CashuSendState state;
  final List<String> checkedOperationIds = [];
  final List<String> reclaimedOperationIds = [];

  @override
  Future<CashuSendState> checkSendStatus({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) async {
    checkedOperationIds.add(operationId);
    return state;
  }

  @override
  Future<CashuAmount> reclaimSend({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) async {
    reclaimedOperationIds.add(operationId);
    return CashuAmount.sats(10);
  }
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
