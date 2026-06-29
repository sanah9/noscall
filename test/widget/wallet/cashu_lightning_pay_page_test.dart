import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/application/cashu_lightning_pay_controller.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';
import 'package:noscall/wallet/domain/wallet_configuration.dart';
import 'package:noscall/wallet/pages/cashu_lightning_pay_page.dart';

void main() {
  testWidgets('creates quote and pays a Lightning invoice', (tester) async {
    final controller = _FakeLightningPayController();

    await tester.pumpWidget(
      MaterialApp(
        home: CashuLightningPayPage(controllerFactory: () async => controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Test Mint'), findsOneWidget);
    await tester.enterText(find.byType(TextField), ' lnbc420n1test ');
    await tester.tap(find.text('Create payment quote'));
    await tester.pumpAndSettle();

    expect(find.text('42 sat'), findsOneWidget);
    expect(find.textContaining('Fee reserve: 2 sat'), findsOneWidget);
    expect(find.textContaining('Maximum spend: 44 sat'), findsOneWidget);
    expect(controller.createdInvoices, ['lnbc420n1test']);

    await tester.ensureVisible(find.text('Pay invoice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pay invoice'));
    await tester.pumpAndSettle();

    expect(find.text('Payment complete'), findsOneWidget);
    expect(find.textContaining('Spent: 43 sat'), findsOneWidget);
    expect(find.text('Paid 43 sat, fee 1 sat.'), findsOneWidget);
    expect(controller.paidQuoteIds, ['melt-quote-1']);
  });

  testWidgets('shows empty state without Lightning pay Mints', (tester) async {
    final controller = _FakeLightningPayController(options: const []);

    await tester.pumpWidget(
      MaterialApp(
        home: CashuLightningPayPage(controllerFactory: () async => controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No enabled Mint supports Lightning pay'),
      findsOneWidget,
    );
  });

  testWidgets('continues a persisted Lightning pay quote', (tester) async {
    final controller = _FakeLightningPayController()
      ..records.add(
        CashuLightningPayQuoteRecord(
          owner: _owner,
          quoteId: 'melt-quote-1',
          mintUrl: _mintUrl,
          amount: CashuAmount.sats(42),
          request: 'lnbc420n1test',
          feeReserve: CashuAmount.sats(2),
          state: CashuQuoteState.unpaid,
          expiry: DateTime.utc(2026, 6, 29, 12),
          createdAt: DateTime.utc(2026, 6, 29, 11),
          updatedAt: DateTime.utc(2026, 6, 29, 12),
        ),
      );

    await tester.pumpWidget(
      MaterialApp(
        home: CashuLightningPayPage(controllerFactory: () async => controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recent payments'), findsOneWidget);
    expect(find.textContaining('Fee reserve: 2 sat'), findsOneWidget);

    await tester.ensureVisible(find.text('Pay invoice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pay invoice'));
    await tester.pumpAndSettle();

    expect(find.text('Payment complete'), findsOneWidget);
    expect(controller.paidQuoteIds, ['melt-quote-1']);
  });

  testWidgets('shows expired persisted Lightning pay quote as not payable', (
    tester,
  ) async {
    final controller = _FakeLightningPayController()
      ..records.add(_record(CashuQuoteState.expired));

    await tester.pumpWidget(
      MaterialApp(
        home: CashuLightningPayPage(controllerFactory: () async => controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recent payments'), findsOneWidget);
    expect(find.textContaining('Status: expired'), findsOneWidget);
    await tester.ensureVisible(find.text('Pay invoice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pay invoice'));
    await tester.pumpAndSettle();

    expect(controller.paidQuoteIds, isEmpty);
  });
}

final class _FakeLightningPayController implements CashuLightningPayController {
  _FakeLightningPayController({List<CashuLightningPayMintOption>? options})
    : options =
          options ??
          [CashuLightningPayMintOption(mint: _mint, balanceSats: 100)];

  final List<CashuLightningPayMintOption> options;
  final List<CashuLightningPayQuoteRecord> records = [];
  final List<String> createdInvoices = [];
  final List<String> paidQuoteIds = [];

  @override
  Future<List<CashuLightningPayMintOption>> loadPayOptions() async => options;

  @override
  Future<List<CashuLightningPayQuoteRecord>> loadQuoteRecords() async =>
      records;

  @override
  Future<CashuMeltQuote> createQuote({
    required CashuMintUrl mintUrl,
    required String bolt11Invoice,
  }) async {
    createdInvoices.add(bolt11Invoice);
    records
      ..clear()
      ..add(_record(CashuQuoteState.unpaid));
    return CashuMeltQuote(
      quoteId: 'melt-quote-1',
      mintUrl: mintUrl,
      amount: CashuAmount.sats(42),
      request: 'lnbc420n1test',
      feeReserve: CashuAmount.sats(2),
      state: CashuQuoteState.unpaid,
      expiry: DateTime.utc(2026, 6, 29, 12),
    );
  }

  @override
  Future<CashuMeltResult> payQuote({
    required CashuMintUrl mintUrl,
    required String quoteId,
  }) async {
    paidQuoteIds.add(quoteId);
    records
      ..clear()
      ..add(
        _record(
          CashuQuoteState.paid,
          amountSpent: CashuAmount.sats(43),
          feePaid: CashuAmount.sats(1),
          paymentPreimage: 'preimage',
        ),
      );
    return CashuMeltResult(
      quoteId: quoteId,
      state: CashuQuoteState.paid,
      amountSpent: CashuAmount.sats(43),
      feePaid: CashuAmount.sats(1),
      paymentPreimage: 'preimage',
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
    CashuNut.nut05,
    CashuNut.nut06,
    CashuNut.nut07,
    CashuNut.nut08,
    CashuNut.nut09,
    CashuNut.nut23,
  },
  units: const ['sat'],
  lastSyncAt: DateTime.utc(2026, 6, 29),
);

CashuLightningPayQuoteRecord _record(
  CashuQuoteState state, {
  CashuAmount? amountSpent,
  CashuAmount? feePaid,
  String? paymentPreimage,
}) {
  return CashuLightningPayQuoteRecord(
    owner: _owner,
    quoteId: 'melt-quote-1',
    mintUrl: _mintUrl,
    amount: CashuAmount.sats(42),
    request: 'lnbc420n1test',
    feeReserve: CashuAmount.sats(2),
    state: state,
    expiry: DateTime.utc(2026, 6, 29, 12),
    createdAt: DateTime.utc(2026, 6, 29, 11),
    updatedAt: DateTime.utc(2026, 6, 29, 12),
    amountSpent: amountSpent,
    feePaid: feePaid,
    paymentPreimage: paymentPreimage,
  );
}
