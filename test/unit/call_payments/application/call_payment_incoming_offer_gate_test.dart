import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/call_payments/application/call_payment_incoming_offer_gate.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/domain/call_payment_repositories.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_event_codec.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  test('allows incoming offer when local payment policy is missing', () async {
    final gate = _gate(
      policyRepository: _PolicyRepository(),
      sessionRepository: _SessionRepository(),
    );

    final decision = await gate.evaluate(
      callId: 'call-1',
      peerPubkey: _peerPubkey,
      callType: CallPaymentCallType.audio,
    );

    expect(decision.allowed, isTrue);
    expect(decision.rejectReason, isNull);
  });

  test('allows incoming offer when local policy makes peer free', () async {
    final policyRepository = _PolicyRepository()
      ..policy = _policy(freePolicy: CallPaymentFreePolicy.contactsFree);
    final gate = _gate(
      policyRepository: policyRepository,
      sessionRepository: _SessionRepository(),
      peerIsContact: (_) => true,
    );

    final decision = await gate.evaluate(
      callId: 'call-1',
      peerPubkey: _peerPubkey,
      callType: CallPaymentCallType.audio,
    );

    expect(decision.allowed, isTrue);
  });

  test('rejects paid incoming offer without matching paid session', () async {
    final sender = _RequiredSender();
    final gate = _gate(
      policyRepository: _PolicyRepository()..policy = _policy(),
      sessionRepository: _SessionRepository(),
      sendPaymentRequired: sender.send,
    );

    final decision = await gate.evaluate(
      callId: 'call-1',
      peerPubkey: _peerPubkey,
      callType: CallPaymentCallType.audio,
    );

    expect(decision.allowed, isFalse);
    expect(decision.rejectReason, 'payment_required_upgrade');
    expect(sender.receiverPubkeys, [_peerPubkey]);
    expect(sender.payloads.single.type, CallPaymentEventType.required);
    expect(sender.payloads.single.payerPubkey, _peerPubkey);
    expect(sender.payloads.single.payeePubkey, _owner.value);
    expect(sender.payloads.single.amountSats, 10);
    expect(sender.payloads.single.billingPeriodSeconds, 60);
    expect(sender.payloads.single.mintUrl, _mintUrl);
    expect(sender.payloads.single.token, isNull);
  });

  test(
    'waits briefly for a matching paid session before allowing offer',
    () async {
      final sessionRepository = _SessionRepository();
      final sender = _RequiredSender();
      final saveSession = Future<void>.delayed(
        const Duration(milliseconds: 5),
        () => sessionRepository.save(_session(chargedSats: 10)),
      );
      final gate = _gate(
        policyRepository: _PolicyRepository()..policy = _policy(),
        sessionRepository: sessionRepository,
        sendPaymentRequired: sender.send,
        paymentWaitWindow: const Duration(milliseconds: 100),
        paymentPollInterval: const Duration(milliseconds: 1),
      );

      final decision = await gate.evaluate(
        callId: 'call-1',
        peerPubkey: _peerPubkey,
        callType: CallPaymentCallType.audio,
      );
      await saveSession;

      expect(decision.allowed, isTrue);
      expect(sender.payloads, isEmpty);
    },
  );

  test(
    'allows paid incoming offer after initial payment is recorded',
    () async {
      final sessionRepository = _SessionRepository()
        ..sessions['${_owner.value}|call-1'] = _session(chargedSats: 10);
      final gate = _gate(
        policyRepository: _PolicyRepository()..policy = _policy(),
        sessionRepository: sessionRepository,
        sendPaymentRequired: _RequiredSender().send,
      );

      final decision = await gate.evaluate(
        callId: 'call-1',
        peerPubkey: _peerPubkey,
        callType: CallPaymentCallType.audio,
      );

      expect(decision.allowed, isTrue);
    },
  );

  test('rejects paid incoming offer when session amount is too low', () async {
    final sessionRepository = _SessionRepository()
      ..sessions['${_owner.value}|call-1'] = _session(chargedSats: 9);
    final sender = _RequiredSender();
    final gate = _gate(
      policyRepository: _PolicyRepository()..policy = _policy(),
      sessionRepository: sessionRepository,
      sendPaymentRequired: sender.send,
    );

    final decision = await gate.evaluate(
      callId: 'call-1',
      peerPubkey: _peerPubkey,
      callType: CallPaymentCallType.audio,
    );

    expect(decision.allowed, isFalse);
    expect(decision.rejectReason, 'payment_required_upgrade');
    expect(sender.payloads.single.amountSats, 10);
  });

  test('still rejects paid offers when required event send fails', () async {
    final gate = _gate(
      policyRepository: _PolicyRepository()..policy = _policy(),
      sessionRepository: _SessionRepository(),
      sendPaymentRequired: _RequiredSender(throwOnSend: true).send,
    );

    final decision = await gate.evaluate(
      callId: 'call-1',
      peerPubkey: _peerPubkey,
      callType: CallPaymentCallType.audio,
    );

    expect(decision.allowed, isFalse);
    expect(decision.rejectReason, 'payment_required_upgrade');
  });

  test(
    'rejects paid incoming offer when session call type mismatches',
    () async {
      final sessionRepository = _SessionRepository()
        ..sessions['${_owner.value}|call-1'] = _session(
          callType: CallPaymentCallType.video,
          chargedSats: 30,
        );
      final gate = _gate(
        policyRepository: _PolicyRepository()..policy = _policy(),
        sessionRepository: sessionRepository,
      );

      final decision = await gate.evaluate(
        callId: 'call-1',
        peerPubkey: _peerPubkey,
        callType: CallPaymentCallType.audio,
      );

      expect(decision.allowed, isFalse);
      expect(decision.rejectReason, 'payment_required_upgrade');
    },
  );

  test(
    'rejects paid incoming offer when session mint is no longer accepted',
    () async {
      final sessionRepository = _SessionRepository()
        ..sessions['${_owner.value}|call-1'] = _session(
          chargedSats: 10,
          mintUrl: CashuMintUrl.parse('https://old.example'),
        );
      final gate = _gate(
        policyRepository: _PolicyRepository()..policy = _policy(),
        sessionRepository: sessionRepository,
      );

      final decision = await gate.evaluate(
        callId: 'call-1',
        peerPubkey: _peerPubkey,
        callType: CallPaymentCallType.audio,
      );

      expect(decision.allowed, isFalse);
      expect(decision.rejectReason, 'payment_required_upgrade');
    },
  );

  test(
    'rejects paid incoming offer when session billing period mismatches',
    () async {
      final sessionRepository = _SessionRepository()
        ..sessions['${_owner.value}|call-1'] = _session(
          chargedSats: 10,
          billingPeriodSeconds: 30,
        );
      final gate = _gate(
        policyRepository: _PolicyRepository()..policy = _policy(),
        sessionRepository: sessionRepository,
      );

      final decision = await gate.evaluate(
        callId: 'call-1',
        peerPubkey: _peerPubkey,
        callType: CallPaymentCallType.audio,
      );

      expect(decision.allowed, isFalse);
      expect(decision.rejectReason, 'payment_required_upgrade');
    },
  );
}

final _owner = CashuAccountId.fromNostrPubkey('a' * 64);
final _mintUrl = CashuMintUrl.parse('https://mint.example');
final _peerPubkey = 'b' * 64;

CallPaymentIncomingOfferGate _gate({
  required _PolicyRepository policyRepository,
  required _SessionRepository sessionRepository,
  bool Function(String peerPubkey)? peerIsContact,
  CallPaymentRequiredSender? sendPaymentRequired,
  Duration paymentWaitWindow = Duration.zero,
  Duration paymentPollInterval = const Duration(milliseconds: 1),
}) {
  return CallPaymentIncomingOfferGate(
    owner: _owner,
    policyRepository: policyRepository,
    sessionRepository: sessionRepository,
    peerIsContact: peerIsContact ?? (_) => false,
    sendPaymentRequired: sendPaymentRequired,
    paymentWaitWindow: paymentWaitWindow,
    paymentPollInterval: paymentPollInterval,
    clock: () => DateTime.utc(2026, 8, 14, 10),
  );
}

CallPaymentPolicy _policy({
  bool enabled = true,
  CallPaymentFreePolicy freePolicy = CallPaymentFreePolicy.everyonePays,
}) {
  return CallPaymentPolicy(
    owner: _owner,
    enabled: enabled,
    freePolicy: freePolicy,
    freePubkeys: const [],
    audioPriceSatsPerMinute: 10,
    videoPriceSatsPerMinute: 30,
    billingPeriodSeconds: 60,
    gracePeriodSeconds: 10,
    acceptedMintUrls: [_mintUrl],
    createdAt: DateTime.utc(2026, 8, 14, 10),
    updatedAt: DateTime.utc(2026, 8, 14, 10),
  );
}

CallPaymentSession _session({
  CallPaymentCallType callType = CallPaymentCallType.audio,
  int chargedSats = 10,
  CashuMintUrl? mintUrl,
  int billingPeriodSeconds = 60,
}) {
  return CallPaymentSession(
    owner: _owner,
    callId: 'call-1',
    peerPubkey: _peerPubkey,
    direction: CallPaymentCallDirection.incoming,
    role: CallPaymentRole.payee,
    callType: callType,
    status: CallPaymentSessionStatus.ringing,
    mintUrl: mintUrl ?? _mintUrl,
    priceSatsPerMinute: callType == CallPaymentCallType.video ? 30 : 10,
    billingPeriodSeconds: billingPeriodSeconds,
    maxSpendSats: 100,
    connectedDurationSeconds: 0,
    chargedSats: chargedSats,
    refundedSats: 0,
    createdAt: DateTime.utc(2026, 8, 14, 10),
    updatedAt: DateTime.utc(2026, 8, 14, 10),
  );
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

final class _RequiredSender {
  _RequiredSender({this.throwOnSend = false});

  final bool throwOnSend;
  final List<String> receiverPubkeys = [];
  final List<CallPaymentEventPayload> payloads = [];

  Future<OKEvent> send({
    required String receiverPubkey,
    required CallPaymentEventPayload payload,
  }) async {
    if (throwOnSend) throw StateError('send failed');
    receiverPubkeys.add(receiverPubkey);
    payloads.add(payload);
    return OKEvent('required-event-1', true, 'ok');
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
