import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/application/cashu_lightning_receive_controller.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';
import 'package:noscall/wallet/domain/wallet_configuration.dart';
import 'package:noscall/wallet/pages/cashu_lightning_receive_page.dart';

void main() {
  testWidgets('creates, checks, and mints a Lightning invoice', (tester) async {
    final controller = _FakeLightningReceiveController();

    await tester.pumpWidget(
      MaterialApp(
        home: CashuLightningReceivePage(
          controllerFactory: () async => controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test Mint'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '21');
    await tester.tap(find.text('Create invoice'));
    await tester.pumpAndSettle();

    expect(find.text('lnbc210n1test'), findsOneWidget);
    expect(find.textContaining('Status: unpaid'), findsOneWidget);

    await tester.tap(find.text('Check payment'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Status: paid'), findsOneWidget);
    expect(find.text('Invoice is paid. You can mint it now.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mint paid quote'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mint paid quote'));
    await tester.pumpAndSettle();

    expect(controller.createdAmounts, [21]);
    expect(controller.checkedQuoteIds, ['quote-1']);
    expect(controller.mintedQuoteIds, ['quote-1']);
  });
}

final class _FakeLightningReceiveController
    implements CashuLightningReceiveController {
  final List<int> createdAmounts = [];
  final List<String> checkedQuoteIds = [];
  final List<String> mintedQuoteIds = [];

  @override
  Future<List<CashuLightningReceiveMintOption>> loadReceiveOptions() async => [
    CashuLightningReceiveMintOption(mint: _mint),
  ];

  @override
  Future<CashuMintQuote> createQuote({
    required CashuMintUrl mintUrl,
    required CashuAmount amount,
  }) async {
    createdAmounts.add(amount.value);
    return _quote(CashuQuoteState.unpaid);
  }

  @override
  Future<CashuMintQuote> checkQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  }) async {
    checkedQuoteIds.add(quoteId);
    return _quote(CashuQuoteState.paid);
  }

  @override
  Future<CashuAmount> mintQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  }) async {
    mintedQuoteIds.add(quoteId);
    return CashuAmount.sats(21);
  }

  CashuMintQuote _quote(CashuQuoteState state) {
    return CashuMintQuote(
      quoteId: 'quote-1',
      mintUrl: _mintUrl,
      amount: CashuAmount.sats(21),
      request: 'lnbc210n1test',
      state: state,
      expiry: DateTime.utc(2026, 6, 29, 12),
    );
  }
}

final _owner = CashuAccountId.fromNostrPubkey('a' * 64);
final _mintUrl = CashuMintUrl.parse('https://mint.example.com');
final _mint = MintConfiguration(
  owner: _owner,
  url: _mintUrl,
  name: 'Test Mint',
  description: 'Test description',
  enabled: true,
  source: MintConfigurationSource.manual,
  supportedNuts: const {
    CashuNut.nut00,
    CashuNut.nut01,
    CashuNut.nut02,
    CashuNut.nut03,
    CashuNut.nut04,
    CashuNut.nut06,
    CashuNut.nut07,
    CashuNut.nut09,
    CashuNut.nut23,
  },
  units: const ['sat'],
  lastSyncAt: DateTime.utc(2026, 6, 29),
);
