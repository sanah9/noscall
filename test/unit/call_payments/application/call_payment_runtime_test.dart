import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/call_payments/application/call_payment_coordinator.dart';
import 'package:noscall/call_payments/application/call_payment_initial_payment_service.dart';
import 'package:noscall/call_payments/application/call_payment_pricing_service.dart';
import 'package:noscall/call_payments/application/call_payment_runtime.dart';
import 'package:noscall/call_payments/application/call_payment_start_guard.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/domain/call_payment_repositories.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/wallet/domain/account_wallet.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  test('builds start guard from peer policy and wallet balances', () async {
    final mint = CashuMintUrl.parse('https://mint.example');
    final policyRepository = _PolicyRepository()
      ..policies[_peer] = _policy(owner: _peer, mints: [mint]);
    final runtime = _runtime(
      wallet: _Wallet(balances: {mint: 100}),
      policyRepository: policyRepository,
    );

    final decision = await runtime.startGuard.evaluate(
      peerPubkey: _peer.value,
      callType: CallPaymentCallType.audio,
    );

    expect(decision.kind, CallPaymentStartDecisionKind.paid);
    expect(decision.mintUrl, mint);
  });

  test('prepares initial payment through wallet adapter and gateway', () async {
    final mint = CashuMintUrl.parse('https://mint.example');
    final wallet = _Wallet(balances: {mint: 100});
    final gateway = _Gateway(okStatus: true);
    final runtime = _runtime(wallet: wallet, gateway: gateway);

    final result = await runtime.prepareInitialPayment(
      CallPaymentInitialPaymentRequest(
        owner: _owner,
        callId: 'call-1',
        peerPubkey: _peer.value,
        callType: CallPaymentCallType.audio,
        mintUrl: mint,
        amountSats: 10,
        priceSatsPerMinute: 10,
        billingPeriodSeconds: 60,
        maxSpendSats: 100,
      ),
    );

    expect(result.okEvent.status, isTrue);
    expect(wallet.sendRequests.single.amount.value, 10);
    expect(gateway.payloads.single.type, CallPaymentEventType.transfer);
  });

  test('builds event handler for incoming transfers', () async {
    final mint = CashuMintUrl.parse('https://mint.example');
    final wallet = _Wallet(balances: {mint: 100});
    final gateway = _Gateway(okStatus: true);
    final runtime = _runtime(wallet: wallet, gateway: gateway);
    final handler = runtime.eventHandler(
      resolveCallType: (_, _) => CallPaymentCallType.audio,
    );

    final result = await handler.handle(
      await _event(
        CallPaymentEventPayload(
          type: CallPaymentEventType.transfer,
          callId: 'call-1',
          paymentSessionId: 'payment-session-1',
          sequence: 1,
          purpose: CallPaymentPurpose.initial,
          callType: CallPaymentCallType.audio,
          payerPubkey: _peer.value,
          payeePubkey: _owner.value,
          mintUrl: mint,
          amountSats: 10,
          billingPeriodSeconds: 60,
          coversFromSecond: 0,
          coversToSecond: 60,
          tokenHash: 'hash-1',
          createdAt: DateTime.utc(2026, 8, 14, 10),
          expiresAt: DateTime.utc(2026, 8, 14, 10, 1),
          token: 'cashuAey',
        ),
      ),
    );

    expect(result.handled, isTrue);
    expect(wallet.receiveRequests.single.encodedToken, 'cashuAey');
    expect(gateway.payloads.single.type, CallPaymentEventType.ack);
  });

  test('exposes owner and disposes runtime resources', () async {
    var disposeCalls = 0;
    final runtime = _runtime(dispose: () async => disposeCalls++);

    expect(runtime.owner, _owner);

    await runtime.dispose();

    expect(disposeCalls, 1);
  });
}

final _owner = CashuAccountId.fromNostrPubkey('a' * 64);
final _peer = CashuAccountId.fromNostrPubkey(
  '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798',
);
const _peerPrivkey =
    '0000000000000000000000000000000000000000000000000000000000000001';

CallPaymentRuntime _runtime({
  _Wallet? wallet,
  _PolicyRepository? policyRepository,
  _Gateway? gateway,
  Future<void> Function()? dispose,
}) {
  return CallPaymentRuntime(
    owner: _owner,
    wallet: wallet ?? _Wallet(),
    policyRepository: policyRepository ?? _PolicyRepository(),
    sessionRepository: _SessionRepository(),
    installmentRepository: _InstallmentRepository(),
    gateway: gateway ?? _Gateway(okStatus: true),
    peerIsContact: (_) => false,
    scheduler: _Scheduler(),
    clock: () => DateTime.utc(2026, 8, 14, 10),
    dispose: dispose,
  );
}

CallPaymentPolicy _policy({
  required CashuAccountId owner,
  required Iterable<CashuMintUrl> mints,
}) {
  final now = DateTime.utc(2026, 8, 14, 9);
  final updatedAt = DateTime.utc(2026, 8, 14, 9, 55);
  return CallPaymentPolicy(
    owner: owner,
    enabled: true,
    freePolicy: CallPaymentFreePolicy.everyonePays,
    freePubkeys: const [],
    audioPriceSatsPerMinute:
        CallPaymentPricingService.defaultAudioPriceSatsPerMinute,
    videoPriceSatsPerMinute:
        CallPaymentPricingService.defaultVideoPriceSatsPerMinute,
    billingPeriodSeconds: CallPaymentPricingService.defaultBillingPeriodSeconds,
    gracePeriodSeconds: CallPaymentPricingService.defaultGracePeriodSeconds,
    acceptedMintUrls: mints,
    createdAt: now,
    updatedAt: updatedAt,
  );
}

Future<Event> _event(CallPaymentEventPayload payload) {
  return Event.from(
    kind: payload.type.kind,
    tags: [
      ['p', _owner.value],
      ['call-id', payload.callId],
      ['payment-session-id', payload.paymentSessionId],
      ['payment-type', payload.type.value],
    ],
    content: const CallPaymentEventCodec().encode(payload),
    pubkey: _peer.value,
    privkey: _peerPrivkey,
  );
}

final class _PolicyRepository implements CallPaymentPolicyRepository {
  final Map<CashuAccountId, CallPaymentPolicy> policies = {};

  @override
  Future<CallPaymentPolicy?> find(CashuAccountId owner) async {
    return policies[owner];
  }

  @override
  Future<void> save(CallPaymentPolicy policy) async {
    policies[policy.owner] = policy;
  }
}

final class _Wallet implements AccountWalletSession {
  _Wallet({Map<CashuMintUrl, int>? balances}) : _balances = balances ?? {};

  final Map<CashuMintUrl, int> _balances;
  final List<CashuSendRequest> sendRequests = [];
  final List<CashuReceiveRequest> receiveRequests = [];

  @override
  CashuAccountId get accountId => _owner;

  @override
  Future<Map<CashuMintUrl, int>> balancesByMintSats() async => _balances;

  @override
  Future<CashuPreparedSend> prepareSend(CashuSendRequest request) async {
    sendRequests.add(request);
    return CashuPreparedSend(
      operationId: 'send-op-1',
      token: 'cashuAey',
      amount: request.amount,
    );
  }

  @override
  Future<CashuReceiveResult> receive(CashuReceiveRequest request) async {
    receiveRequests.add(request);
    return CashuReceiveResult(
      operationId: 'receive-op-1',
      amount: CashuAmount.sats(10),
    );
  }

  @override
  Future<CashuSendState> checkSendStatus({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> close() async {}

  @override
  Future<CashuMintQuote> checkMintQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CashuMintQuote> createMintQuote({
    required CashuMintUrl mintUrl,
    required CashuAmount amount,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CashuMeltQuote> createMeltQuote({
    required CashuMintUrl mintUrl,
    required String bolt11Invoice,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CashuMeltResult> meltQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CashuAmount> mintQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CashuAmount> reclaimSend({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CashuReconciliationResult> reconcilePendingOperations() {
    throw UnimplementedError();
  }

  @override
  Future<int> totalBalanceSats() {
    throw UnimplementedError();
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

final class _Scheduler implements CallPaymentLifecycleScheduler {
  @override
  void cancel(Object handle) {}

  @override
  Object schedule(Duration delay, Future<void> Function() callback) => 1;
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
