import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';

void main() {
  test('normalizes a Nostr hex public key', () {
    final account = CashuAccountId.fromNostrPubkey(' A${'B' * 63} ');

    expect(account.value, 'a${'b' * 63}');
    expect(account.seedReference, startsWith('cashu-wallet-seed-v1:'));
  });

  test('rejects non-hex and path-like account identifiers', () {
    expect(
      () => CashuAccountId.fromNostrPubkey('../${'a' * 61}'),
      throwsFormatException,
    );
    expect(
      () => CashuAccountId.fromNostrPubkey('g${'0' * 63}'),
      throwsFormatException,
    );
  });
}
