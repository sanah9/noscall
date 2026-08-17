import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/call_payments/application/call_payment_initial_payment_service.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/domain/call_payment_repositories.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/utils/hash_util.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  test('prepares, sends, and records an initial payment transfer', () async {
    final sessionRepository = _SessionRepository();
    final installmentRepository = _InstallmentRepository();
    final tokenSender = _TokenSender(token: 'cashuAey-initial');
    final gateway = _Gateway(okStatus: true);
    final service = _service(
      sessionRepository: sessionRepository,
      installmentRepository: installmentRepository,
      tokenSender: tokenSender,
      gateway: gateway,
    );

    final result = await service.prepareAndSend(_request());

    expect(result.okEvent.status, isTrue);
    expect(result.session.status, CallPaymentSessionStatus.initialPaymentSent);
    expect(result.session.chargedSats, 10);
    expect(result.installment.status, CallPaymentInstallmentStatus.sent);
    expect(result.installment.walletOperationId, 'op-1');
    expect(
      result.installment.tokenHash,
      HashUtil.sha256String('cashuAey-initial'),
    );
    expect(result.installment.sentAt, isNotNull);
    expect(gateway.payloads.single.type, CallPaymentEventType.transfer);
    expect(gateway.payloads.single.callType, CallPaymentCallType.audio);
    expect(gateway.payloads.single.token, 'cashuAey-initial');
    expect(gateway.payloads.single.tokenHash, result.installment.tokenHash);

    final savedInstallments = await installmentRepository.listForCall(
      owner: _owner,
      callId: 'call-1',
    );
    expect(savedInstallments.single.tokenHash, result.installment.tokenHash);
  });

  test(
    'marks payment failed when transfer event is not acknowledged',
    () async {
      final sessionRepository = _SessionRepository();
      final installmentRepository = _InstallmentRepository();
      final service = _service(
        sessionRepository: sessionRepository,
        installmentRepository: installmentRepository,
        tokenSender: _TokenSender(token: 'cashuAey-failed'),
        gateway: _Gateway(okStatus: false),
      );

      final result = await service.prepareAndSend(_request());

      expect(result.okEvent.status, isFalse);
      expect(result.session.status, CallPaymentSessionStatus.paymentFailed);
      expect(result.session.chargedSats, 0);
      expect(result.installment.status, CallPaymentInstallmentStatus.failed);
      expect(result.installment.sentAt, isNull);
      expect(result.installment.errorCode, 'payment_transfer_send_failed');
      expect(
        result.installment.tokenHash,
        HashUtil.sha256String('cashuAey-failed'),
      );
    },
  );

  test('rejects requests where max spend cannot cover first period', () async {
    final service = _service(
      sessionRepository: _SessionRepository(),
      installmentRepository: _InstallmentRepository(),
      tokenSender: _TokenSender(token: 'cashuAey'),
      gateway: _Gateway(okStatus: true),
    );

    await expectLater(
      service.prepareAndSend(_request(maxSpendSats: 9)),
      throwsA(isA<ArgumentError>()),
    );
  });
}

final _owner = CashuAccountId.fromNostrPubkey('a' * 64);
final _mintUrl = CashuMintUrl.parse('https://mint.example');

CallPaymentInitialPaymentService _service({
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
  return CallPaymentInitialPaymentService(
    sessionRepository: sessionRepository,
    installmentRepository: installmentRepository,
    tokenSender: tokenSender,
    gateway: gateway,
    clock: () => times[index++ < times.length ? index - 1 : times.length - 1],
  );
}

CallPaymentInitialPaymentRequest _request({int maxSpendSats = 100}) {
  return CallPaymentInitialPaymentRequest(
    owner: _owner,
    callId: 'call-1',
    peerPubkey: 'b' * 64,
    callType: CallPaymentCallType.audio,
    mintUrl: _mintUrl,
    amountSats: 10,
    priceSatsPerMinute: 10,
    billingPeriodSeconds: 60,
    maxSpendSats: maxSpendSats,
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
