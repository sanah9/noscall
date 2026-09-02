import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call_payments/application/call_payment_ack_service.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/domain/call_payment_repositories.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  test('marks sent installment claimed and moves session to ringing', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    await sessionRepository.save(_session());
    await installmentRepository.save(_installment());
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
    );

    final result = await service.apply(_request());

    expect(result.installment.status, CallPaymentInstallmentStatus.claimed);
    expect(result.installment.claimedAt, DateTime.utc(2026, 8, 14, 10));
    expect(result.installment.errorCode, isNull);
    expect(result.session.status, CallPaymentSessionStatus.ringing);
    expect(result.session.chargedSats, 10);
  });

  test('rejects ack payloads from another payee', () async {
    final service = _service(
      sessionRepository: _SessionRepository(),
      installmentRepository: _InstallmentRepository(),
    );

    await expectLater(
      service.apply(_request(payload: _payload(payeePubkey: 'c' * 64))),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('rejects ack payloads that do not match the sent installment', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    await sessionRepository.save(_session());
    await installmentRepository.save(_installment());
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
    );

    await expectLater(
      service.apply(_request(payload: _payload(tokenHash: 'other-hash'))),
      throwsA(isA<ArgumentError>()),
    );

    final installment = await installmentRepository.find(
      owner: _owner,
      callId: 'call-1',
      sequence: 1,
      purpose: CallPaymentPurpose.initial,
      direction: CallPaymentTransferDirection.sent,
    );
    expect(installment?.status, CallPaymentInstallmentStatus.sent);
  });

  test('keeps first claimed timestamp when ack is duplicated', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    final claimedAt = DateTime.utc(2026, 8, 14, 9, 59);
    await sessionRepository.save(_session());
    await installmentRepository.save(
      _installment(
        status: CallPaymentInstallmentStatus.claimed,
        claimedAt: claimedAt,
      ),
    );
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
    );

    final result = await service.apply(_request());

    expect(result.installment.status, CallPaymentInstallmentStatus.claimed);
    expect(result.installment.claimedAt, claimedAt);
  });

  test('top-up ack keeps connected sessions connected', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    await sessionRepository.save(
      _session(status: CallPaymentSessionStatus.connected, chargedSats: 20),
    );
    await installmentRepository.save(
      _installment(
        sequence: 2,
        purpose: CallPaymentPurpose.topUp,
        coversFromSecond: 60,
        coversToSecond: 120,
      ),
    );
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
    );

    final result = await service.apply(
      _request(
        payload: _payload(
          sequence: 2,
          purpose: CallPaymentPurpose.topUp,
          coversFromSecond: 60,
          coversToSecond: 120,
        ),
      ),
    );

    expect(result.installment.status, CallPaymentInstallmentStatus.claimed);
    expect(result.installment.purpose, CallPaymentPurpose.topUp);
    expect(result.session.status, CallPaymentSessionStatus.connected);
    expect(result.session.chargedSats, 20);
  });

  test('fails when matching sent installment is missing', () async {
    final sessionRepository = _SessionRepository();
    await sessionRepository.save(_session());
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: _InstallmentRepository(),
    );

    await expectLater(service.apply(_request()), throwsA(isA<StateError>()));
  });
}

final _owner = CashuAccountId.fromNostrPubkey('a' * 64);
final _mintUrl = CashuMintUrl.parse('https://mint.example');

CallPaymentAckService _service({
  required _SessionRepository sessionRepository,
  required _InstallmentRepository installmentRepository,
}) {
  return CallPaymentAckService(
    sessionRepository: sessionRepository,
    installmentRepository: installmentRepository,
    clock: () => DateTime.utc(2026, 8, 14, 10),
  );
}

CallPaymentAckRequest _request({CallPaymentEventPayload? payload}) {
  return CallPaymentAckRequest(
    owner: _owner,
    senderPubkey: 'b' * 64,
    payload: payload ?? _payload(),
  );
}

CallPaymentEventPayload _payload({
  String? payeePubkey,
  int sequence = 1,
  CallPaymentPurpose purpose = CallPaymentPurpose.initial,
  int coversFromSecond = 0,
  int coversToSecond = 60,
  String tokenHash = 'hash-1',
}) {
  return CallPaymentEventPayload(
    type: CallPaymentEventType.ack,
    callId: 'call-1',
    paymentSessionId: 'payment-session-1',
    sequence: sequence,
    purpose: purpose,
    callType: CallPaymentCallType.audio,
    payerPubkey: _owner.value,
    payeePubkey: payeePubkey ?? 'b' * 64,
    mintUrl: _mintUrl,
    amountSats: 10,
    billingPeriodSeconds: 60,
    coversFromSecond: coversFromSecond,
    coversToSecond: coversToSecond,
    tokenHash: tokenHash,
    createdAt: DateTime.utc(2026, 8, 14, 10),
    expiresAt: DateTime.utc(2026, 8, 14, 10, 1),
  );
}

CallPaymentSession _session({
  CallPaymentSessionStatus status = CallPaymentSessionStatus.initialPaymentSent,
  int chargedSats = 10,
}) {
  final now = DateTime.utc(2026, 8, 14, 9);
  return CallPaymentSession(
    owner: _owner,
    callId: 'call-1',
    peerPubkey: 'b' * 64,
    direction: CallPaymentCallDirection.outgoing,
    role: CallPaymentRole.payer,
    callType: CallPaymentCallType.audio,
    status: status,
    mintUrl: _mintUrl,
    priceSatsPerMinute: 10,
    billingPeriodSeconds: 60,
    maxSpendSats: 100,
    connectedDurationSeconds: 0,
    chargedSats: chargedSats,
    refundedSats: 0,
    createdAt: now,
    updatedAt: now,
  );
}

CallPaymentInstallment _installment({
  int sequence = 1,
  CallPaymentPurpose purpose = CallPaymentPurpose.initial,
  int coversFromSecond = 0,
  int coversToSecond = 60,
  CallPaymentInstallmentStatus status = CallPaymentInstallmentStatus.sent,
  DateTime? claimedAt,
}) {
  final now = DateTime.utc(2026, 8, 14, 9);
  return CallPaymentInstallment(
    owner: _owner,
    callId: 'call-1',
    paymentSessionId: 'payment-session-1',
    sequence: sequence,
    purpose: purpose,
    direction: CallPaymentTransferDirection.sent,
    amountSats: 10,
    mintUrl: _mintUrl,
    walletOperationId: 'send-op-1',
    tokenHash: 'hash-1',
    status: status,
    coversFromSecond: coversFromSecond,
    coversToSecond: coversToSecond,
    createdAt: now,
    claimedAt: claimedAt,
    updatedAt: now,
    errorCode: 'old_error',
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
