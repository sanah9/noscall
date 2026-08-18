import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call_payments/application/call_payment_incoming_transfer_service.dart';
import 'package:noscall/call_payments/application/call_payment_refund_service.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/domain/call_payment_repositories.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  test('receives refund token and completes fully refunded session', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    final receiver = _TokenReceiver();
    await sessionRepository.save(_session());
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      receiver: receiver,
    );

    final result = await service.receive(_request());

    expect(receiver.tokens, ['cashuRefund']);
    expect(result.installment.purpose, CallPaymentPurpose.refund);
    expect(result.installment.direction, CallPaymentTransferDirection.received);
    expect(result.installment.status, CallPaymentInstallmentStatus.refunded);
    expect(result.installment.walletOperationId, 'receive-refund-op-1');
    expect(result.installment.claimedAt, DateTime.utc(2026, 8, 14, 10));
    expect(result.installment.refundedAt, DateTime.utc(2026, 8, 14, 10));
    expect(result.session.status, CallPaymentSessionStatus.completed);
    expect(result.session.refundedSats, 10);
    expect(result.session.netSats, 0);
  });

  test('keeps session refund pending after partial refund', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    await sessionRepository.save(_session(chargedSats: 20));
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      receiver: _TokenReceiver(),
    );

    final result = await service.receive(
      _request(payload: _payload(amountSats: 10)),
    );

    expect(result.session.status, CallPaymentSessionStatus.refundPending);
    expect(result.session.refundedSats, 10);
    expect(result.session.netSats, 10);
  });

  test('does not receive duplicate refund events twice', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    final receiver = _TokenReceiver();
    await sessionRepository.save(_session(refundedSats: 10));
    await installmentRepository.save(_refundInstallment());
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      receiver: receiver,
    );

    final result = await service.receive(_request());

    expect(receiver.tokens, isEmpty);
    expect(result.installment.walletOperationId, 'receive-refund-op-1');
    expect(result.session.refundedSats, 10);
  });

  test('rejects refund payloads from another payee', () async {
    final service = _service(
      sessionRepository: _SessionRepository(),
      installmentRepository: _InstallmentRepository(),
      receiver: _TokenReceiver(),
    );

    await expectLater(
      service.receive(_request(payload: _payload(payeePubkey: 'c' * 64))),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('rejects refunds without a matching payer session', () async {
    final service = _service(
      sessionRepository: _SessionRepository(),
      installmentRepository: _InstallmentRepository(),
      receiver: _TokenReceiver(),
    );

    await expectLater(service.receive(_request()), throwsA(isA<StateError>()));
  });
}

final _owner = CashuAccountId.fromNostrPubkey('a' * 64);
const _peerPubkey =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
final _mintUrl = CashuMintUrl.parse('https://mint.example');

CallPaymentRefundService _service({
  required _SessionRepository sessionRepository,
  required _InstallmentRepository installmentRepository,
  required _TokenReceiver receiver,
}) {
  return CallPaymentRefundService(
    sessionRepository: sessionRepository,
    installmentRepository: installmentRepository,
    tokenReceiver: receiver,
    clock: () => DateTime.utc(2026, 8, 14, 10),
  );
}

CallPaymentRefundRequest _request({CallPaymentEventPayload? payload}) {
  return CallPaymentRefundRequest(
    owner: _owner,
    senderPubkey: _peerPubkey,
    payload: payload ?? _payload(),
  );
}

CallPaymentEventPayload _payload({String? payeePubkey, int amountSats = 10}) {
  return CallPaymentEventPayload(
    type: CallPaymentEventType.refund,
    callId: 'call-1',
    paymentSessionId: 'payment-session-1',
    sequence: 1,
    purpose: CallPaymentPurpose.refund,
    callType: CallPaymentCallType.audio,
    payerPubkey: _owner.value,
    payeePubkey: payeePubkey ?? _peerPubkey,
    mintUrl: _mintUrl,
    amountSats: amountSats,
    billingPeriodSeconds: 60,
    coversFromSecond: 0,
    coversToSecond: 60,
    tokenHash: 'refund-hash-1',
    createdAt: DateTime.utc(2026, 8, 14, 10),
    expiresAt: DateTime.utc(2026, 8, 14, 10, 1),
    token: 'cashuRefund',
  );
}

CallPaymentSession _session({int chargedSats = 10, int refundedSats = 0}) {
  final now = DateTime.utc(2026, 8, 14, 9);
  return CallPaymentSession(
    owner: _owner,
    callId: 'call-1',
    peerPubkey: _peerPubkey,
    direction: CallPaymentCallDirection.outgoing,
    role: CallPaymentRole.payer,
    callType: CallPaymentCallType.audio,
    status: CallPaymentSessionStatus.refundPending,
    mintUrl: _mintUrl,
    priceSatsPerMinute: 10,
    billingPeriodSeconds: 60,
    maxSpendSats: 100,
    connectedDurationSeconds: 0,
    chargedSats: chargedSats,
    refundedSats: refundedSats,
    createdAt: now,
    updatedAt: now,
  );
}

CallPaymentInstallment _refundInstallment() {
  final now = DateTime.utc(2026, 8, 14, 9);
  return CallPaymentInstallment(
    owner: _owner,
    callId: 'call-1',
    paymentSessionId: 'payment-session-1',
    sequence: 1,
    purpose: CallPaymentPurpose.refund,
    direction: CallPaymentTransferDirection.received,
    amountSats: 10,
    mintUrl: _mintUrl,
    walletOperationId: 'receive-refund-op-1',
    tokenHash: 'refund-hash-1',
    status: CallPaymentInstallmentStatus.refunded,
    coversFromSecond: 0,
    coversToSecond: 60,
    createdAt: now,
    claimedAt: now,
    refundedAt: now,
    updatedAt: now,
  );
}

final class _TokenReceiver implements CallPaymentTokenReceiver {
  final List<String> tokens = [];

  @override
  Future<CashuReceiveResult> receive(String encodedToken) async {
    tokens.add(encodedToken);
    return CashuReceiveResult(
      operationId: 'receive-refund-op-1',
      amount: CashuAmount.sats(10),
    );
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
