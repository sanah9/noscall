import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call_payments/application/call_payment_required_service.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/domain/call_payment_repositories.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  test('moves sent payer sessions to reclaim pending', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    await sessionRepository.save(_session());
    await installmentRepository.save(
      _installment(status: CallPaymentInstallmentStatus.sent),
    );
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
    );

    final result = await service.apply(_request());

    expect(result.session.status, CallPaymentSessionStatus.reclaimPending);
    expect(result.session.updatedAt, DateTime.utc(2026, 8, 14, 10));
  });

  test('moves claimed payer sessions to refund pending', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    await sessionRepository.save(_session());
    await installmentRepository.save(
      _installment(status: CallPaymentInstallmentStatus.claimed),
    );
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
    );

    final result = await service.apply(_request());

    expect(result.session.status, CallPaymentSessionStatus.refundPending);
  });

  test('marks payer sessions without recoverable payment failed', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    await sessionRepository.save(_session());
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
    );

    final result = await service.apply(_request());

    expect(result.session.status, CallPaymentSessionStatus.paymentFailed);
  });

  test('rejects required payloads from another payee', () async {
    final service = _service(
      sessionRepository: _SessionRepository(),
      installmentRepository: _InstallmentRepository(),
    );

    await expectLater(
      service.apply(_request(payload: _payload(payeePubkey: 'c' * 64))),
      throwsA(isA<ArgumentError>()),
    );
  });

  test(
    'rejects required payloads for a different initial payment quote',
    () async {
      final sessionRepository = _SessionRepository();
      await sessionRepository.save(_session());
      final service = _service(
        sessionRepository: sessionRepository,
        installmentRepository: _InstallmentRepository(),
      );

      await expectLater(
        service.apply(_request(payload: _payload(amountSats: 20))),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        service.apply(
          _request(
            payload: _payload(
              mintUrl: CashuMintUrl.parse('https://other-mint.example'),
            ),
          ),
        ),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        service.apply(_request(payload: _payload(coversFromSecond: 60))),
        throwsA(isA<ArgumentError>()),
      );
    },
  );

  test('rejects required events without matching payer session', () async {
    final service = _service(
      sessionRepository: _SessionRepository(),
      installmentRepository: _InstallmentRepository(),
    );

    await expectLater(service.apply(_request()), throwsA(isA<StateError>()));
  });
}

final _owner = CashuAccountId.fromNostrPubkey('a' * 64);
const _peerPubkey =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
final _mintUrl = CashuMintUrl.parse('https://mint.example');

CallPaymentRequiredService _service({
  required _SessionRepository sessionRepository,
  required _InstallmentRepository installmentRepository,
}) {
  return CallPaymentRequiredService(
    sessionRepository: sessionRepository,
    installmentRepository: installmentRepository,
    clock: () => DateTime.utc(2026, 8, 14, 10),
  );
}

CallPaymentRequiredRequest _request({CallPaymentEventPayload? payload}) {
  return CallPaymentRequiredRequest(
    owner: _owner,
    senderPubkey: _peerPubkey,
    payload: payload ?? _payload(),
  );
}

CallPaymentEventPayload _payload({
  String? payeePubkey,
  CashuMintUrl? mintUrl,
  int amountSats = 10,
  int coversFromSecond = 0,
  int coversToSecond = 60,
}) {
  return CallPaymentEventPayload(
    type: CallPaymentEventType.required,
    callId: 'call-1',
    paymentSessionId: 'call-1:required',
    sequence: 1,
    purpose: CallPaymentPurpose.initial,
    callType: CallPaymentCallType.audio,
    payerPubkey: _owner.value,
    payeePubkey: payeePubkey ?? _peerPubkey,
    mintUrl: mintUrl ?? _mintUrl,
    amountSats: amountSats,
    billingPeriodSeconds: 60,
    coversFromSecond: coversFromSecond,
    coversToSecond: coversToSecond,
    tokenHash: 'required-hash-1',
    createdAt: DateTime.utc(2026, 8, 14, 10),
    expiresAt: DateTime.utc(2026, 8, 14, 10, 1),
  );
}

CallPaymentSession _session() {
  final now = DateTime.utc(2026, 8, 14, 9);
  return CallPaymentSession(
    owner: _owner,
    callId: 'call-1',
    peerPubkey: _peerPubkey,
    direction: CallPaymentCallDirection.outgoing,
    role: CallPaymentRole.payer,
    callType: CallPaymentCallType.audio,
    status: CallPaymentSessionStatus.initialPaymentSent,
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

CallPaymentInstallment _installment({
  required CallPaymentInstallmentStatus status,
}) {
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
    walletOperationId: 'send-op-1',
    tokenHash: 'hash-1',
    status: status,
    coversFromSecond: 0,
    coversToSecond: 60,
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
