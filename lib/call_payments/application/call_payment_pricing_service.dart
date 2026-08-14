import '../domain/call_payment_models.dart';

final class CallPaymentPricingQuote {
  const CallPaymentPricingQuote({
    required this.isFree,
    required this.priceSatsPerMinute,
    required this.periodAmountSats,
    required this.billingPeriodSeconds,
    required this.gracePeriodSeconds,
    required this.defaultMaxSpendSats,
    required this.freeReason,
  });

  final bool isFree;
  final int priceSatsPerMinute;
  final int periodAmountSats;
  final int billingPeriodSeconds;
  final int gracePeriodSeconds;
  final int defaultMaxSpendSats;
  final String? freeReason;
}

final class CallPaymentPricingService {
  const CallPaymentPricingService();

  static const defaultAudioPriceSatsPerMinute = 10;
  static const defaultVideoPriceSatsPerMinute = 30;
  static const defaultBillingPeriodSeconds = 60;
  static const defaultGracePeriodSeconds = 10;
  static const defaultMaxSpendPeriods = 10;

  CallPaymentPricingQuote quote({
    required CallPaymentPolicy policy,
    required CallPaymentCallType callType,
    required String peerPubkey,
    required bool peerIsContact,
  }) {
    final price = priceFor(policy: policy, callType: callType);
    final freeReason = _freeReason(
      policy: policy,
      priceSatsPerMinute: price,
      peerPubkey: peerPubkey,
      peerIsContact: peerIsContact,
    );
    final periodAmount = freeReason == null
        ? periodAmountSats(
            priceSatsPerMinute: price,
            billingPeriodSeconds: policy.billingPeriodSeconds,
          )
        : 0;

    return CallPaymentPricingQuote(
      isFree: freeReason != null,
      priceSatsPerMinute: price,
      periodAmountSats: periodAmount,
      billingPeriodSeconds: policy.billingPeriodSeconds,
      gracePeriodSeconds: policy.gracePeriodSeconds,
      defaultMaxSpendSats: periodAmount * defaultMaxSpendPeriods,
      freeReason: freeReason,
    );
  }

  int priceFor({
    required CallPaymentPolicy policy,
    required CallPaymentCallType callType,
  }) {
    return switch (callType) {
      CallPaymentCallType.audio => policy.audioPriceSatsPerMinute,
      CallPaymentCallType.video => policy.videoPriceSatsPerMinute,
    };
  }

  int periodAmountSats({
    required int priceSatsPerMinute,
    required int billingPeriodSeconds,
  }) {
    if (priceSatsPerMinute <= 0) return 0;
    return (priceSatsPerMinute * billingPeriodSeconds / 60).ceil();
  }

  String? _freeReason({
    required CallPaymentPolicy policy,
    required int priceSatsPerMinute,
    required String peerPubkey,
    required bool peerIsContact,
  }) {
    if (!policy.enabled) return 'policy_disabled';
    if (priceSatsPerMinute == 0) return 'zero_price';
    return switch (policy.freePolicy) {
      CallPaymentFreePolicy.everyoneFree => 'everyone_free',
      CallPaymentFreePolicy.contactsFree when peerIsContact => 'contact_free',
      CallPaymentFreePolicy.whitelistFree
          when policy.freePubkeys.contains(peerPubkey) =>
        'whitelist_free',
      _ => null,
    };
  }
}
