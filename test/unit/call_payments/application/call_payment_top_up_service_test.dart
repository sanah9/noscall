import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/call_payments/application/call_payment_initial_payment_service.dart';
import 'package:noscall/call_payments/application/call_payment_top_up_service.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/domain/call_payment_repositories.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/utils/hash_util.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  test('prepares and sends the next top-up payment period', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    await sessionRepository.save(_session());
    await installmentRepository.save(_installment());
    final tokenSender = _TokenSender(token: 'cashuAey-top-up');
    final gateway = _Gateway(okStatus: true);
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      tokenSender: tokenSender,
      gateway: gateway,
    );

    final result = await service.prepareAndSend(_request());

    expect(result.okEvent.status, isTrue);
    expect(result.session.status, CallPaymentSessionStatus.connected);
    expect(result.session.chargedSats, 20);
    expect(result.installment.sequence, 2);
    expect(result.installment.purpose, CallPaymentPurpose.topUp);
    expect(result.installment.status, CallPaymentInstallmentStatus.sent);
    expect(result.installment.coversFromSecond, 60);
    expect(result.installment.coversToSecond, 120);
    expect(result.installment.walletOperationId, 'op-1');
    expect(
      result.installment.tokenHash,
      HashUtil.sha256String('cashuAey-top-up'),
    );
    expect(gateway.payloads.single.type, CallPaymentEventType.transfer);
    expect(gateway.payloads.single.purpose, CallPaymentPurpose.topUp);
    expect(gateway.payloads.single.sequence, 2);
    expect(gateway.payloads.single.token, 'cashuAey-top-up');
  });

  test('does not increase charged sats when top-up send fails', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    await sessionRepository.save(_session());
    await installmentRepository.save(_installment());
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      tokenSender: _TokenSender(token: 'cashuAey-failed'),
      gateway: _Gateway(okStatus: false),
    );

    final result = await service.prepareAndSend(_request());

    expect(result.okEvent.status, isFalse);
    expect(result.session.status, CallPaymentSessionStatus.paymentFailed);
    expect(result.session.chargedSats, 10);
    expect(result.installment.status, CallPaymentInstallmentStatus.failed);
    expect(result.installment.errorCode, 'payment_top_up_send_failed');
  });

  test('rejects top-up when max spend is reached', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    await sessionRepository.save(_session(maxSpendSats: 10));
    await installmentRepository.save(_installment());
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      tokenSender: _TokenSender(token: 'cashuAey'),
      gateway: _Gateway(okStatus: true),
    );

    await expectLater(
      service.prepareAndSend(_request()),
      throwsA(isA<StateError>()),
    );
    final savedInstallments = await installmentRepository.listForCall(
      owner: _owner,
      callId: 'call-1',
    );
    expect(savedInstallments, hasLength(1));
  });

  test('requires an existing payer session', () async {
    final service = _service(
      sessionRepository: _SessionRepository(),
      installmentRepository: _InstallmentRepository(),
      tokenSender: _TokenSender(token: 'cashuAey'),
      gateway: _Gateway(okStatus: true),
    );

    await expectLater(
      service.prepareAndSend(_request()),
      throwsA(isA<StateError>()),
    );
  });
}

final _owner = CashuAccountId.fromNostrPubkey('a' * 64);
const _peerPubkey =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
final _mintUrl = CashuMintUrl.parse('https://mint.example');

CallPaymentTopUpService _service({
  required _SessionRepository sessionRepository,
  required _InstallmentRepository installmentRepository,
  required _TokenSender tokenSender,
  required _Gateway gateway,
}) {
  final times = [
    DateTime.utc(2026, 8, 14, 10),
    DateTime.utc(2026, 8, 14, 10, 0, 1),
    DateTime.utc(2026, 8, 14, 10, 0, 2),
  ];
  var index = 0;
  return CallPaymentTopUpService(
    sessionRepository: sessionRepository,
    installmentRepository: installmentRepository,
    tokenSender: tokenSender,
    gateway: gateway,
    clock: () => times[index++ < times.length ? index - 1 : times.length - 1],
  );
}

CallPaymentTopUpRequest _request() {
  return CallPaymentTopUpRequest(owner: _owner, callId: 'call-1');
}

CallPaymentSession _session({int maxSpendSats = 100}) {
  final now = DateTime.utc(2026, 8, 14, 9);
  return CallPaymentSession(
    owner: _owner,
    callId: 'call-1',
    peerPubkey: _peerPubkey,
    direction: CallPaymentCallDirection.outgoing,
    role: CallPaymentRole.payer,
    callType: CallPaymentCallType.audio,
    status: CallPaymentSessionStatus.connected,
    mintUrl: _mintUrl,
    priceSatsPerMinute: 10,
    billingPeriodSeconds: 60,
    maxSpendSats: maxSpendSats,
    connectedAt: now,
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
    walletOperationId: 'send-op-0',
    tokenHash: 'hash-0',
    status: CallPaymentInstallmentStatus.claimed,
    coversFromSecond: 0,
    coversToSecond: 60,
    createdAt: now,
    updatedAt: now,
  );
}

final class _TokenSender implements CallPaymentTokenSender {
  _TokenSender({required this.token});

  final String token;

  @override
  Future<CashuPreparedSend> prepareSend({
    required CashuMintUrl mintUrl,
    required CashuAmount amount,
    String? memo,
  }) async {
    return CashuPreparedSend(operationId: 'op-1', token: token, amount: amount);
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
    return OKEvent('event-1', okStatus, okStatus ? 'ok' : 'failed');
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
