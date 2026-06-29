import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/application/cashu_token_controller.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';
import 'package:noscall/wallet/domain/wallet_configuration.dart';
import 'package:noscall/wallet/pages/cashu_token_send_page.dart';

void main() {
  testWidgets('generates, checks, and reclaims a Cashu token', (tester) async {
    final controller = _FakeTokenController();

    await tester.pumpWidget(
      MaterialApp(
        home: CashuTokenSendPage(controllerFactory: () async => controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Test Mint'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), '42');
    await tester.enterText(find.byType(TextField).at(1), 'lunch');
    await tester.tap(find.text('Generate token'));
    await tester.pumpAndSettle();

    expect(find.text('cashu-generated-token'), findsOneWidget);
    expect(controller.sentAmounts, [42]);
    expect(controller.sentMemos, ['lunch']);

    await tester.ensureVisible(find.text('Check status').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check status').first);
    await tester.pumpAndSettle();
    expect(find.text('Token is still recoverable.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Reclaim').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reclaim').first);
    await tester.pumpAndSettle();
    expect(controller.reclaimCalls, 1);
  });
}

final class _FakeTokenController implements CashuTokenController {
  final List<int> sentAmounts = [];
  final List<String?> sentMemos = [];
  final List<CashuTokenSendRecord> records = [];
  int reclaimCalls = 0;

  @override
  Future<List<CashuTokenMintOption>> loadSendOptions() async => [
    CashuTokenMintOption(mint: _mint, balanceSats: 100),
  ];

  @override
  Future<List<CashuTokenSendRecord>> loadSendRecords() async => records;

  @override
  Future<CashuPreparedSend> prepareSend({
    required CashuMintUrl mintUrl,
    required CashuAmount amount,
    String? memo,
  }) async {
    sentAmounts.add(amount.value);
    sentMemos.add(memo);
    records
      ..clear()
      ..add(
        CashuTokenSendRecord(
          owner: _owner,
          operationId: 'send-1',
          mintUrl: mintUrl,
          amount: amount,
          state: CashuSendState.recoverable,
          createdAt: DateTime.utc(2026, 6, 29),
          updatedAt: DateTime.utc(2026, 6, 29),
          memo: memo,
        ),
      );
    return CashuPreparedSend(
      operationId: 'send-1',
      token: 'cashu-generated-token',
      amount: amount,
    );
  }

  @override
  Future<CashuSendState> checkSendStatus({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) async {
    _updateRecord(operationId, CashuSendState.recoverable);
    return CashuSendState.recoverable;
  }

  @override
  Future<CashuAmount> reclaimSend({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) async {
    reclaimCalls++;
    _updateRecord(operationId, CashuSendState.reclaimed);
    return CashuAmount.sats(42);
  }

  @override
  Future<CashuTokenSummary> previewReceive(String encodedToken) =>
      throw UnimplementedError();

  @override
  Future<CashuReceiveResult> receive(String encodedToken) =>
      throw UnimplementedError();

  void _updateRecord(String operationId, CashuSendState state) {
    final index = records.indexWhere(
      (record) => record.operationId == operationId,
    );
    if (index == -1) return;
    records[index] = records[index].copyWith(
      state: state,
      updatedAt: DateTime.utc(2026, 6, 29, 1),
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
    CashuNut.nut06,
    CashuNut.nut07,
    CashuNut.nut09,
  },
  units: const ['sat'],
  lastSyncAt: DateTime.utc(2026, 6, 29),
);
