import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/call_payments/application/call_payment_incoming_transfer_service.dart';
import 'package:noscall/call_payments/application/call_payment_initial_payment_service.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/domain/call_payment_repositories.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  test(
    'receives transfer token, records incoming payment, and sends ack',
    () async {
      final sessionRepository = _SessionRepository();
      final installmentRepository = _InstallmentRepository();
      final receiver = _TokenReceiver();
      final gateway = _Gateway(okStatus: true);
      final service = _service(
        sessionRepository: sessionRepository,
        installmentRepository: installmentRepository,
        receiver: receiver,
        gateway: gateway,
      );

      final result = await service.receiveAndAck(_request());

      expect(receiver.tokens.single, 'cashuAey-transfer');
      expect(result.ackEvent.status, isTrue);
      expect(result.session.status, CallPaymentSessionStatus.ringing);
      expect(result.session.role, CallPaymentRole.payee);
      expect(result.session.direction, CallPaymentCallDirection.incoming);
      expect(result.session.chargedSats, 10);
      expect(result.installment.status, CallPaymentInstallmentStatus.claimed);
      expect(result.installment.walletOperationId, 'receive-op-1');
      expect(result.installment.claimedAt, isNotNull);
      expect(result.installment.errorCode, isNull);
      expect(gateway.payloads.single.type, CallPaymentEventType.ack);
      expect(gateway.payloads.single.token, isNull);
      expect(gateway.payloads.single.payeePubkey, _owner.value);
    },
  );

  test('keeps claimed installment and records error when ack fails', () async {
    final service = _service(
      sessionRepository: _SessionRepository(),
      installmentRepository: _InstallmentRepository(),
      receiver: _TokenReceiver(),
      gateway: _Gateway(okStatus: false),
    );

    final result = await service.receiveAndAck(_request());

    expect(result.ackEvent.status, isFalse);
    expect(result.installment.status, CallPaymentInstallmentStatus.claimed);
    expect(result.installment.errorCode, 'payment_ack_send_failed');
  });

  test('top-up transfer updates existing connected incoming session', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    final connectedAt = DateTime.utc(2026, 8, 14, 9, 59);
    await sessionRepository.save(_session(connectedAt: connectedAt));
    await installmentRepository.save(_installment());
    final receiver = _TokenReceiver();
    final gateway = _Gateway(okStatus: true);
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      receiver: receiver,
      gateway: gateway,
    );

    final result = await service.receiveAndAck(
      _request(
        payload: _payload(
          purpose: CallPaymentPurpose.topUp,
          sequence: 2,
          coversFromSecond: 60,
          coversToSecond: 120,
          token: 'cashuAey-top-up',
        ),
      ),
    );

    expect(receiver.tokens.single, 'cashuAey-top-up');
    expect(result.session.status, CallPaymentSessionStatus.connected);
    expect(result.session.connectedAt, connectedAt);
    expect(result.session.chargedSats, 20);
    expect(result.installment.purpose, CallPaymentPurpose.topUp);
    expect(result.installment.sequence, 2);
    expect(result.installment.coversFromSecond, 60);
    expect(result.installment.coversToSecond, 120);
    expect(gateway.payloads.single.purpose, CallPaymentPurpose.topUp);
  });

  test(
    'rejects top-up transfer without an existing connected incoming session',
    () async {
      final receiver = _TokenReceiver();
      final gateway = _Gateway(okStatus: true);
      final service = _service(
        sessionRepository: _SessionRepository(),
        installmentRepository: _InstallmentRepository(),
        receiver: receiver,
        gateway: gateway,
      );

      await expectLater(
        service.receiveAndAck(
          _request(
            payload: _payload(
              purpose: CallPaymentPurpose.topUp,
              sequence: 2,
              coversFromSecond: 60,
              coversToSecond: 120,
              token: 'cashuAey-top-up',
            ),
          ),
        ),
        throwsA(isA<StateError>()),
      );

      expect(receiver.tokens, isEmpty);
      expect(gateway.payloads, isEmpty);
    },
  );

  test(
    'rejects transfer coverage that does not match billing period',
    () async {
      final receiver = _TokenReceiver();
      final gateway = _Gateway(okStatus: true);
      final service = _service(
        sessionRepository: _SessionRepository(),
        installmentRepository: _InstallmentRepository(),
        receiver: receiver,
        gateway: gateway,
      );

      await expectLater(
        service.receiveAndAck(
          _request(payload: _payload(coversFromSecond: 0, coversToSecond: 30)),
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(receiver.tokens, isEmpty);
      expect(gateway.payloads, isEmpty);
    },
  );

  test('rejects top-up transfers that skip the next paid period', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    await sessionRepository.save(_session());
    await installmentRepository.save(_installment());
    final receiver = _TokenReceiver();
    final gateway = _Gateway(okStatus: true);
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      receiver: receiver,
      gateway: gateway,
    );

    await expectLater(
      service.receiveAndAck(
        _request(
          payload: _payload(
            purpose: CallPaymentPurpose.topUp,
            sequence: 2,
            coversFromSecond: 120,
            coversToSecond: 180,
            token: 'cashuAey-top-up',
          ),
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );

    expect(receiver.tokens, isEmpty);
    expect(gateway.payloads, isEmpty);
  });

  test('rejects top-up transfers for a different payment session', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    await sessionRepository.save(_session());
    await installmentRepository.save(_installment());
    final receiver = _TokenReceiver();
    final gateway = _Gateway(okStatus: true);
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      receiver: receiver,
      gateway: gateway,
    );

    await expectLater(
      service.receiveAndAck(
        _request(
          payload: _payload(
            paymentSessionId: 'other-payment-session',
            purpose: CallPaymentPurpose.topUp,
            sequence: 2,
            coversFromSecond: 60,
            coversToSecond: 120,
            token: 'cashuAey-top-up',
          ),
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );

    expect(receiver.tokens, isEmpty);
    expect(gateway.payloads, isEmpty);
  });

  test(
    'duplicate transfer resends ack without receiving token again',
    () async {
      final sessionRepository = _SessionRepository();
      final installmentRepository = _InstallmentRepository();
      await sessionRepository.save(_session());
      await installmentRepository.save(_installment());
      final receiver = _TokenReceiver();
      final gateway = _Gateway(okStatus: true);
      final service = _service(
        sessionRepository: sessionRepository,
        installmentRepository: installmentRepository,
        receiver: receiver,
        gateway: gateway,
      );

      final result = await service.receiveAndAck(_request());

      expect(receiver.tokens, isEmpty);
      expect(result.session.chargedSats, 10);
      expect(result.installment.status, CallPaymentInstallmentStatus.claimed);
      expect(gateway.payloads.single.type, CallPaymentEventType.ack);
    },
  );

  test(
    'rejects duplicate transfer payloads that do not match stored payment',
    () async {
      final sessionRepository = _SessionRepository();
      final installmentRepository = _InstallmentRepository();
      await sessionRepository.save(_session());
      await installmentRepository.save(_installment());
      final receiver = _TokenReceiver();
      final gateway = _Gateway(okStatus: true);
      final service = _service(
        sessionRepository: sessionRepository,
        installmentRepository: installmentRepository,
        receiver: receiver,
        gateway: gateway,
      );

      await expectLater(
        service.receiveAndAck(
          _request(payload: _payload(tokenHash: 'other-hash')),
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(receiver.tokens, isEmpty);
      expect(gateway.payloads, isEmpty);
    },
  );

  test('rejects transfer payloads for another payee', () async {
    final service = _service(
      sessionRepository: _SessionRepository(),
      installmentRepository: _InstallmentRepository(),
      receiver: _TokenReceiver(),
      gateway: _Gateway(okStatus: true),
    );

    await expectLater(
      service.receiveAndAck(_request(payload: _payload(payeePubkey: 'c' * 64))),
      throwsA(isA<ArgumentError>()),
    );
  });

  test(
    'rejects paid transfer below local policy price before receiving',
    () async {
      final receiver = _TokenReceiver();
      final gateway = _Gateway(okStatus: true);
      final service = _service(
        sessionRepository: _SessionRepository(),
        installmentRepository: _InstallmentRepository(),
        receiver: receiver,
        gateway: gateway,
        policyRepository: _PolicyRepository()
          ..policy = _policy(audioPriceSatsPerMinute: 20),
      );

      await expectLater(
        service.receiveAndAck(_request()),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            'payment_insufficient',
          ),
        ),
      );

      expect(receiver.tokens, isEmpty);
      expect(gateway.payloads, isEmpty);
    },
  );

  test(
    'rejects paid transfer from unsupported mint before receiving',
    () async {
      final receiver = _TokenReceiver();
      final gateway = _Gateway(okStatus: true);
      final service = _service(
        sessionRepository: _SessionRepository(),
        installmentRepository: _InstallmentRepository(),
        receiver: receiver,
        gateway: gateway,
        policyRepository: _PolicyRepository()
          ..policy = _policy(
            acceptedMintUrls: [CashuMintUrl.parse('https://other.example')],
          ),
      );

      await expectLater(
        service.receiveAndAck(_request()),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            'payment_mint_not_accepted',
          ),
        ),
      );

      expect(receiver.tokens, isEmpty);
      expect(gateway.payloads, isEmpty);
    },
  );
}

final _owner = CashuAccountId.fromNostrPubkey('b' * 64);
final _mintUrl = CashuMintUrl.parse('https://mint.example');

CallPaymentIncomingTransferService _service({
  required _SessionRepository sessionRepository,
  required _InstallmentRepository installmentRepository,
  required _TokenReceiver receiver,
  required _Gateway gateway,
  _PolicyRepository? policyRepository,
  bool Function(String peerPubkey)? peerIsContact,
}) {
  final times = [
    DateTime.utc(2026, 8, 14, 10),
    DateTime.utc(2026, 8, 14, 10, 0, 1),
    DateTime.utc(2026, 8, 14, 10, 0, 2),
  ];
  var index = 0;
  return CallPaymentIncomingTransferService(
    sessionRepository: sessionRepository,
    installmentRepository: installmentRepository,
    tokenReceiver: receiver,
    gateway: gateway,
    policyRepository: policyRepository,
    peerIsContact: peerIsContact,
    clock: () => times[index++ < times.length ? index - 1 : times.length - 1],
  );
}

CallPaymentIncomingTransferRequest _request({
  CallPaymentEventPayload? payload,
}) {
  return CallPaymentIncomingTransferRequest(
    owner: _owner,
    senderPubkey: 'a' * 64,
    callType: CallPaymentCallType.audio,
    payload: payload ?? _payload(),
  );
}

CallPaymentPolicy _policy({
  int audioPriceSatsPerMinute = 10,
  Iterable<CashuMintUrl>? acceptedMintUrls,
}) {
  return CallPaymentPolicy(
    owner: _owner,
    enabled: true,
    freePolicy: CallPaymentFreePolicy.everyonePays,
    freePubkeys: const [],
    audioPriceSatsPerMinute: audioPriceSatsPerMinute,
    videoPriceSatsPerMinute: 30,
    billingPeriodSeconds: 60,
    gracePeriodSeconds: 10,
    acceptedMintUrls: acceptedMintUrls ?? [_mintUrl],
    createdAt: DateTime.utc(2026, 8, 14, 9),
    updatedAt: DateTime.utc(2026, 8, 14, 9),
  );
}

CallPaymentEventPayload _payload({
  String paymentSessionId = 'payment-session-1',
  String? payeePubkey,
  CallPaymentPurpose purpose = CallPaymentPurpose.initial,
  int sequence = 1,
  int coversFromSecond = 0,
  int coversToSecond = 60,
  String token = 'cashuAey-transfer',
  String tokenHash = 'hash-1',
}) {
  return CallPaymentEventPayload(
    type: CallPaymentEventType.transfer,
    callId: 'call-1',
    paymentSessionId: paymentSessionId,
    sequence: sequence,
    purpose: purpose,
    callType: CallPaymentCallType.audio,
    payerPubkey: 'a' * 64,
    payeePubkey: payeePubkey ?? _owner.value,
    mintUrl: _mintUrl,
    amountSats: 10,
    billingPeriodSeconds: 60,
    coversFromSecond: coversFromSecond,
    coversToSecond: coversToSecond,
    tokenHash: tokenHash,
    createdAt: DateTime.utc(2026, 8, 14, 10),
    expiresAt: DateTime.utc(2026, 8, 14, 10, 1),
    token: token,
  );
}

CallPaymentSession _session({DateTime? connectedAt}) {
  final now = DateTime.utc(2026, 8, 14, 9);
  return CallPaymentSession(
    owner: _owner,
    callId: 'call-1',
    peerPubkey: 'a' * 64,
    direction: CallPaymentCallDirection.incoming,
    role: CallPaymentRole.payee,
    callType: CallPaymentCallType.audio,
    status: CallPaymentSessionStatus.connected,
    mintUrl: _mintUrl,
    priceSatsPerMinute: 10,
    billingPeriodSeconds: 60,
    maxSpendSats: 10,
    connectedAt: connectedAt,
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
    direction: CallPaymentTransferDirection.received,
    amountSats: 10,
    mintUrl: _mintUrl,
    walletOperationId: 'receive-op-1',
    tokenHash: 'hash-1',
    status: CallPaymentInstallmentStatus.claimed,
    coversFromSecond: 0,
    coversToSecond: 60,
    createdAt: now,
    claimedAt: now,
    updatedAt: now,
  );
}

final class _TokenReceiver implements CallPaymentTokenReceiver {
  final List<String> tokens = [];

  @override
  Future<CashuReceiveResult> receive(String encodedToken) async {
    tokens.add(encodedToken);
    return CashuReceiveResult(
      operationId: 'receive-op-1',
      amount: CashuAmount.sats(10),
    );
  }
}

final class _Gateway implements CallPaymentTransferGateway {
  _Gateway({required this.okStatus});

  final bool okStatus;
  final List<CallPaymentEventPayload> payloads = [];

  @override
  Future<OKEvent> send({
    required String receiverPubkey,
    required CallPaymentEventPayload payload,
  }) async {
    payloads.add(payload);
    return OKEvent('ack-event-1', okStatus, okStatus ? 'ok' : 'failed');
  }
}

final class _PolicyRepository implements CallPaymentPolicyRepository {
  CallPaymentPolicy? policy;

  @override
  Future<CallPaymentPolicy?> find(CashuAccountId owner) async {
    if (policy?.owner != owner) return null;
    return policy;
  }

  @override
  Future<void> save(CallPaymentPolicy policy) async {
    this.policy = policy;
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
