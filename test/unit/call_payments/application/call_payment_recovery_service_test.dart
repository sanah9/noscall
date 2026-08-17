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
}) {
  final now = DateTime.utc(2026, 8, 14, 9);
  return CallPaymentSession(
    owner: _owner,
    callId: 'call-1',
    peerPubkey: _peerPubkey,
    direction: CallPaymentCallDirection.outgoing,
    role: CallPaymentRole.payer,
    callType: CallPaymentCallType.audio,
    status: status,
    mintUrl: _mintUrl,
    priceSatsPerMinute: 10,
    billingPeriodSeconds: 60,
    maxSpendSats: 100,
    connectedDurationSeconds: 0,
    chargedSats: 10,
    refundedSats: 0,
    createdAt: now,
    updatedAt: now,
  );
}

CallPaymentInstallment _installment() {
  final now = DateTime.utc(2026, 8, 14, 9);
  return CallPaymentInstallment(
    owner: _owner,
    callId: 'call-1',
    paymentSessionId: 'payment-session-1',
    sequence: 1,
    purpose: CallPaymentPurpose.initial,
    direction: CallPaymentTransferDirection.sent,
    amountSats: 10,
    mintUrl: _mintUrl,
    walletOperationId: 'op-1',
    status: CallPaymentInstallmentStatus.sent,
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
