import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call_payments/application/call_payment_pricing_service.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  const service = CallPaymentPricingService();

  test('calculates default audio and video period amounts', () {
    final owner = CashuAccountId.fromNostrPubkey('a' * 64);
    final policy = _policy(owner);

    final audio = service.quote(
      policy: policy,
      callType: CallPaymentCallType.audio,
      peerPubkey: 'b' * 64,
      peerIsContact: false,
    );
    final video = service.quote(
      policy: policy,
      callType: CallPaymentCallType.video,
      peerPubkey: 'b' * 64,
      peerIsContact: false,
    );

    expect(audio.isFree, isFalse);
    expect(audio.priceSatsPerMinute, 10);
    expect(audio.periodAmountSats, 10);
    expect(audio.defaultMaxSpendSats, 100);
    expect(video.priceSatsPerMinute, 30);
    expect(video.periodAmountSats, 30);
    expect(video.defaultMaxSpendSats, 300);
  });

  test('treats disabled, zero price, contacts, and whitelist as free', () {
    final owner = CashuAccountId.fromNostrPubkey('a' * 64);
    final peer = 'b' * 64;

    expect(
      service
          .quote(
            policy: _policy(owner).copyWith(enabled: false),
            callType: CallPaymentCallType.audio,
            peerPubkey: peer,
            peerIsContact: false,
          )
          .freeReason,
      'policy_disabled',
    );
    expect(
      service
          .quote(
            policy: _policy(owner).copyWith(audioPriceSatsPerMinute: 0),
            callType: CallPaymentCallType.audio,
            peerPubkey: peer,
            peerIsContact: false,
          )
          .freeReason,
      'zero_price',
    );
    expect(
      service
          .quote(
            policy: _policy(owner),
            callType: CallPaymentCallType.audio,
            peerPubkey: peer,
            peerIsContact: true,
          )
          .freeReason,
      'contact_free',
    );
    expect(
      service
          .quote(
            policy: _policy(owner).copyWith(
              freePolicy: CallPaymentFreePolicy.whitelistFree,
              freePubkeys: [peer],
            ),
            callType: CallPaymentCallType.audio,
            peerPubkey: peer,
            peerIsContact: false,
          )
          .freeReason,
      'whitelist_free',
    );
  });

  test(
    'rounds up non-minute billing periods even though first release is 60s',
    () {
      expect(
        service.periodAmountSats(
          priceSatsPerMinute: 10,
          billingPeriodSeconds: 15,
        ),
        3,
      );
    },
  );
}

CallPaymentPolicy _policy(CashuAccountId owner) {
  final now = DateTime.utc(2026, 8, 14);
  return CallPaymentPolicy(
    owner: owner,
    enabled: true,
    freePolicy: CallPaymentFreePolicy.contactsFree,
    freePubkeys: const [],
    audioPriceSatsPerMinute: 10,
    videoPriceSatsPerMinute: 30,
    billingPeriodSeconds: 60,
    gracePeriodSeconds: 10,
    acceptedMintUrls: [CashuMintUrl.parse('https://mint.example.com')],
    createdAt: now,
    updatedAt: now,
  );
}
