import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/application/wallet_activity_service.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';
import '../../../helpers/payment_activity_fixtures.dart';

void main() {
  test(
    'merges recorded activity by account and newest first without duplicating calls',
    () {
      final other = CashuAccountId.fromNostrPubkey('b' * 64);
      CashuTokenSendRecord send(String id, CashuAccountId owner) =>
          CashuTokenSendRecord(
            owner: owner,
            operationId: id,
            mintUrl: activityMint,
            amount: CashuAmount.sats(80),
            state: CashuSendState.recoverable,
            createdAt: activityTime.subtract(const Duration(minutes: 2)),
            updatedAt: activityTime,
          );
      final entries = WalletActivityService.merge(
        owner: activityOwner,
        calls: [activityCall()],
        sends: [
          send('call-operation', activityOwner),
          send('manual', activityOwner),
          send('private', other),
        ],
        receives: [
          CashuTokenReceiveRecord(
            owner: activityOwner,
            receiptId: 'receipt',
            mintUrl: activityMint,
            amount: CashuAmount.sats(5),
            state: CashuReceiveState.received,
            createdAt: activityTime.add(const Duration(seconds: 1)),
          ),
        ],
      );
      expect(entries.map((e) => e.id), ['receipt', 'call-1', 'manual']);
      expect(entries[1].amountSats, 80);
      expect(entries.first.pending, isFalse);
      expect(entries.last.pending, isTrue);
    },
  );
  test('Lightning fee is included once and paid invoice awaits issuance', () {
    final entries = WalletActivityService.merge(
      owner: activityOwner,
      lightningPays: [
        CashuLightningPayQuoteRecord(
          owner: activityOwner,
          quoteId: 'pay',
          mintUrl: activityMint,
          amount: CashuAmount.sats(20),
          request: 'secret-invoice',
          feeReserve: CashuAmount.sats(3),
          state: CashuQuoteState.paid,
          expiry: activityTime,
          createdAt: activityTime,
          updatedAt: activityTime,
          amountSpent: CashuAmount.sats(21),
          feePaid: CashuAmount.sats(1),
        ),
      ],
      lightningReceives: [
        CashuLightningReceiveQuoteRecord(
          owner: activityOwner,
          quoteId: 'receive',
          mintUrl: activityMint,
          amount: CashuAmount.sats(10),
          request: 'secret-invoice',
          state: CashuQuoteState.paid,
          expiry: activityTime,
          createdAt: activityTime,
          updatedAt: activityTime,
        ),
      ],
    );
    final pay = entries.firstWhere((e) => e.id == 'pay');
    expect(pay.amountSats, 21);
    expect(pay.detail, contains('1 sat (included)'));
    expect(pay.pending, isFalse);
    expect(entries.firstWhere((e) => e.id == 'receive').pending, isTrue);
  });
}
