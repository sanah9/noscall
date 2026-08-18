import 'package:nostr_core_dart/nostr.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_policy_event_codec.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';

import '../domain/call_payment_models.dart';
import '../domain/call_payment_repositories.dart';
import 'call_payment_initial_payment_service.dart';
import 'call_payment_pricing_service.dart';

typedef CallPaymentPolicyResponseSender =
    Future<OKEvent> Function({
      required String receiverPubkey,
      required CallPaymentPolicyEventPayload payload,
    });

final class CallPaymentPolicyQueryResult {
  const CallPaymentPolicyQueryResult.handled(this.responseEvent)
    : handled = true,
      ignoredReason = null;

  const CallPaymentPolicyQueryResult.ignored(this.ignoredReason)
    : handled = false,
      responseEvent = null;

  final bool handled;
  final OKEvent? responseEvent;
  final String? ignoredReason;
}

final class CallPaymentPolicyQueryHandler {
  CallPaymentPolicyQueryHandler({
    required CashuAccountId owner,
    required CallPaymentPolicyRepository policyRepository,
    required CallPaymentPolicyResponseSender sendResponse,
    CallPaymentPolicyEventCodec codec = const CallPaymentPolicyEventCodec(),
    CallPaymentClock? clock,
  }) : _owner = owner,
       _policyRepository = policyRepository,
       _sendResponse = sendResponse,
       _codec = codec,
       _clock = clock ?? DateTime.now;

  final CashuAccountId _owner;
  final CallPaymentPolicyRepository _policyRepository;
  final CallPaymentPolicyResponseSender _sendResponse;
  final CallPaymentPolicyEventCodec _codec;
  final CallPaymentClock _clock;

  Future<CallPaymentPolicyQueryResult> handle(Event event) async {
    if (event.kind != CallPaymentPolicyEventType.query.kind) {
      return const CallPaymentPolicyQueryResult.ignored(
        'not_policy_query_event',
      );
    }

    final payload = _codec.decode(event.content);
    if (payload.type != CallPaymentPolicyEventType.query) {
      return const CallPaymentPolicyQueryResult.ignored(
        'not_policy_query_payload',
      );
    }
    if (payload.requesterPubkey != event.pubkey ||
        payload.responderPubkey != _owner.value) {
      return const CallPaymentPolicyQueryResult.ignored(
        'policy_query_participants_mismatch',
      );
    }

    final policy =
        await _policyRepository.find(_owner) ?? _disabledDefaultPolicy();
    final response = await _sendResponse(
      receiverPubkey: payload.requesterPubkey,
      payload: CallPaymentPolicyEventPayload(
        type: CallPaymentPolicyEventType.response,
        requestId: payload.requestId,
        requesterPubkey: payload.requesterPubkey,
        responderPubkey: _owner.value,
        policy: policy,
        createdAt: _clock(),
      ),
    );
    return CallPaymentPolicyQueryResult.handled(response);
  }

  CallPaymentPolicy _disabledDefaultPolicy() {
    final now = _clock();
    return CallPaymentPolicy(
      owner: _owner,
      enabled: false,
      freePolicy: CallPaymentFreePolicy.contactsFree,
      freePubkeys: const [],
      audioPriceSatsPerMinute:
          CallPaymentPricingService.defaultAudioPriceSatsPerMinute,
      videoPriceSatsPerMinute:
          CallPaymentPricingService.defaultVideoPriceSatsPerMinute,
      billingPeriodSeconds:
          CallPaymentPricingService.defaultBillingPeriodSeconds,
      gracePeriodSeconds: CallPaymentPricingService.defaultGracePeriodSeconds,
      acceptedMintUrls: const [],
      createdAt: now,
      updatedAt: now,
    );
  }
}
