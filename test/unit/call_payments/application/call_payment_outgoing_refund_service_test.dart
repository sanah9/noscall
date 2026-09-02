import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/call_payments/application/call_payment_initial_payment_service.dart';
import 'package:noscall/call_payments/application/call_payment_outgoing_refund_service.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/domain/call_payment_repositories.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  test('sends refund tokens for claimed received installments', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    final sender = _TokenSender();
    final gateway = _Gateway(okStatus: true);
    await sessionRepository.save(_session());
    await installmentRepository.save(_receivedInstallment());
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      sender: sender,
      gateway: gateway,
    );

    final result = await service.prepareAndSend(_request());

    expect(sender.amounts, [10]);
    expect(gateway.receiverPubkeys, [_payerPubkey]);
    expect(gateway.payloads.single.type, CallPaymentEventType.refund);
    expect(gateway.payloads.single.payerPubkey, _payerPubkey);
    expect(gateway.payloads.single.payeePubkey, _owner.value);
    expect(gateway.payloads.single.purpose, CallPaymentPurpose.refund);
    expect(gateway.payloads.single.token, 'refund-token-1');
    expect(
      result.installments.single.status,
      CallPaymentInstallmentStatus.sent,
    );
    expect(result.installments.single.sentAt, DateTime.utc(2026, 8, 14, 10));
    expect(
      result.installments.single.refundedAt,
      DateTime.utc(2026, 8, 14, 10),
    );
    expect(result.session.status, CallPaymentSessionStatus.completed);
    expect(result.session.refundedSats, 10);
    expect(result.session.netSats, 0);
  });

  test('skips installments that already have outgoing refunds', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    final sender = _TokenSender();
    await sessionRepository.save(_session());
    await installmentRepository.save(_receivedInstallment());
    await installmentRepository.save(_refundInstallment());
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      sender: sender,
      gateway: _Gateway(okStatus: true),
    );

    final result = await service.prepareAndSend(_request());

    expect(sender.amounts, isEmpty);
    expect(result.installments, isEmpty);
    expect(result.session.status, CallPaymentSessionStatus.refundPending);
  });

  test(
    'refunds only unused claimed installments after connected calls',
    () async {
      final sessionRepository = _SessionRepository();
      final installmentRepository = _InstallmentRepository();
      final sender = _TokenSender();
      final gateway = _Gateway(okStatus: true);
      await sessionRepository.save(
        _session(
          connectedAt: DateTime.utc(2026, 8, 14, 10),
          connectedDurationSeconds: 55,
          chargedSats: 20,
        ),
      );
      await installmentRepository.save(
        _receivedInstallment(
          sequence: 1,
          coversFromSecond: 0,
          coversToSecond: 60,
        ),
      );
      await installmentRepository.save(
        _receivedInstallment(
          sequence: 2,
          purpose: CallPaymentPurpose.topUp,
          coversFromSecond: 60,
          coversToSecond: 120,
        ),
      );
      final service = _service(
        sessionRepository: sessionRepository,
        installmentRepository: installmentRepository,
        sender: sender,
        gateway: gateway,
      );

      final result = await service.prepareAndSend(_request());

      expect(sender.amounts, [10]);
      expect(gateway.payloads.single.sequence, 2);
      expect(gateway.payloads.single.coversFromSecond, 60);
      expect(result.installments.single.sequence, 2);
      expect(result.session.status, CallPaymentSessionStatus.completed);
      expect(result.session.refundedSats, 10);
      expect(result.session.netSats, 10);
    },
  );

  test('keeps session refund pending when refund send fails', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    await sessionRepository.save(_session());
    await installmentRepository.save(_receivedInstallment());
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      sender: _TokenSender(),
      gateway: _Gateway(okStatus: false),
    );

    final result = await service.prepareAndSend(_request());

    expect(
      result.installments.single.status,
      CallPaymentInstallmentStatus.failed,
    );
    expect(result.installments.single.errorCode, 'payment_refund_send_failed');
    expect(result.session.status, CallPaymentSessionStatus.refundPending);
    expect(result.session.refundedSats, 0);
  });

  test('rejects payer sessions', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    await sessionRepository.save(_session(role: CallPaymentRole.payer));
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      sender: _TokenSender(),
      gateway: _Gateway(okStatus: true),
    );

    await expectLater(
      service.prepareAndSend(_request()),
      throwsA(isA<StateError>()),
    );
  });

  test('rejects sessions that are not pending refund', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    await sessionRepository.save(
      _session(status: CallPaymentSessionStatus.completed),
    );
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      sender: _TokenSender(),
      gateway: _Gateway(okStatus: true),
    );

    await expectLater(
      service.prepareAndSend(_request()),
      throwsA(isA<StateError>()),
    );
  });
}

final _owner = CashuAccountId.fromNostrPubkey('b' * 64);
const _payerPubkey =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
final _mintUrl = CashuMintUrl.parse('https://mint.example');

CallPaymentOutgoingRefundService _service({
  required _SessionRepository sessionRepository,
  required _InstallmentRepository installmentRepository,
  required _TokenSender sender,
  required _Gateway gateway,
}) {
  return CallPaymentOutgoingRefundService(
    sessionRepository: sessionRepository,
    installmentRepository: installmentRepository,
    tokenSender: sender,
    gateway: gateway,
    clock: () => DateTime.utc(2026, 8, 14, 10),
  );
}

CallPaymentOutgoingRefundRequest _request() {
  return CallPaymentOutgoingRefundRequest(owner: _owner, callId: 'call-1');
}

CallPaymentSession _session({
  CallPaymentRole role = CallPaymentRole.payee,
  CallPaymentSessionStatus status = CallPaymentSessionStatus.refundPending,
  DateTime? connectedAt,
  int connectedDurationSeconds = 0,
  int chargedSats = 10,
}) {
  final now = DateTime.utc(2026, 8, 14, 9);
  return CallPaymentSession(
    owner: _owner,
    callId: 'call-1',
    peerPubkey: _payerPubkey,
    direction: CallPaymentCallDirection.incoming,
    role: role,
    callType: CallPaymentCallType.audio,
    status: status,
    mintUrl: _mintUrl,
    priceSatsPerMinute: 10,
    billingPeriodSeconds: 60,
    maxSpendSats: chargedSats,
    connectedAt: connectedAt,
    connectedDurationSeconds: connectedDurationSeconds,
    chargedSats: chargedSats,
    refundedSats: 0,
    createdAt: now,
    updatedAt: now,
  );
}

CallPaymentInstallment _receivedInstallment({
  int sequence = 1,
  CallPaymentPurpose purpose = CallPaymentPurpose.initial,
  int coversFromSecond = 0,
  int coversToSecond = 60,
}) {
  final now = DateTime.utc(2026, 8, 14, 9);
  return CallPaymentInstallment(
    owner: _owner,
    callId: 'call-1',
    paymentSessionId: 'payment-session-1',
    sequence: sequence,
    purpose: purpose,
    direction: CallPaymentTransferDirection.received,
    amountSats: 10,
    mintUrl: _mintUrl,
    walletOperationId: 'receive-op-1',
    tokenHash: 'transfer-hash-1',
    status: CallPaymentInstallmentStatus.claimed,
    coversFromSecond: coversFromSecond,
    coversToSecond: coversToSecond,
    createdAt: now,
    claimedAt: now,
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
    direction: CallPaymentTransferDirection.sent,
    amountSats: 10,
    mintUrl: _mintUrl,
    walletOperationId: 'refund-op-1',
    tokenHash: 'refund-hash-1',
    status: CallPaymentInstallmentStatus.sent,
    coversFromSecond: 0,
    coversToSecond: 60,
    createdAt: now,
    sentAt: now,
    refundedAt: now,
    updatedAt: now,
  );
}

final class _TokenSender implements CallPaymentTokenSender {
  final List<int> amounts = [];

  @override
  Future<CashuPreparedSend> prepareSend({
    required CashuMintUrl mintUrl,
    required CashuAmount amount,
    String? memo,
  }) async {
    amounts.add(amount.value);
    return CashuPreparedSend(
      operationId: 'refund-op-${amounts.length}',
      token: 'refund-token-${amounts.length}',
      amount: amount,
    );
  }
}

final class _Gateway implements CallPaymentTransferGateway {
  _Gateway({required this.okStatus});

  final bool okStatus;
  final List<String> receiverPubkeys = [];
  final List<CallPaymentEventPayload> payloads = [];

  @override
  Future<OKEvent> send({
    required String receiverPubkey,
    required CallPaymentEventPayload payload,
  }) async {
    receiverPubkeys.add(receiverPubkey);
    payloads.add(payload);
    return OKEvent('refund-event-1', okStatus, okStatus ? 'ok' : 'failed');
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
