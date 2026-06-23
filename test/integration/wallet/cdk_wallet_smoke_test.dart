import 'package:cdk/cdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CDK FFI creates an isolated SQLite wallet', () async {
    final wallet = Wallet(
      mintUrl: 'https://example.com',
      unit: SatCurrencyUnit(),
      mnemonic: generateMnemonic(),
      store: SqliteWalletStore(':memory:'),
      config: WalletConfig(targetProofCount: null),
    );
    addTearDown(wallet.dispose);

    final balance = await wallet.totalBalance();

    expect(balance.value, 0);
  });
}
