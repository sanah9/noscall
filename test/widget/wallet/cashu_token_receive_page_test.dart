import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/application/cashu_token_controller.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';
import 'package:noscall/wallet/pages/cashu_token_receive_page.dart';

void main() {
  testWidgets('previews and receives a pasted Cashu token', (tester) async {
    final controller = _FakeTokenController();

    await tester.pumpWidget(
      MaterialApp(
        home: CashuTokenReceivePage(controllerFactory: () async => controller),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), ' cashu-token ');
    await tester.tap(find.text('Preview token'));
    await tester.pumpAndSettle();

    expect(find.text('21 sat'), findsOneWidget);
    expect(find.text('https://mint.example.com'), findsOneWidget);

    await tester.tap(find.text('Receive token'));
    await tester.pumpAndSettle();

    expect(controller.previewedTokens, [' cashu-token ']);
    expect(controller.receivedTokens, [' cashu-token ']);
  });
}

final class _FakeTokenController implements CashuTokenController {
  final List<String> previewedTokens = [];
  final List<String> receivedTokens = [];

  @override
  Future<List<CashuTokenMintOption>> loadSendOptions() async => const [];

  @override
  Future<List<CashuTokenSendRecord>> loadSendRecords() async => const [];

  @override
  Future<CashuTokenSummary> previewReceive(String encodedToken) async {
    previewedTokens.add(encodedToken);
    return CashuTokenSummary(
      encodedToken: encodedToken.trim(),
      mintUrl: _mintUrl,
      amount: CashuAmount.sats(21),
      version: 4,
      memo: null,
    );
  }

  @override
  Future<CashuReceiveResult> receive(String encodedToken) async {
    receivedTokens.add(encodedToken);
    return CashuReceiveResult(
      operationId: 'receive-1',
      amount: CashuAmount.sats(21),
    );
  }

  @override
  Future<CashuPreparedSend> prepareSend({
    required CashuMintUrl mintUrl,
    required CashuAmount amount,
    String? memo,
  }) => throw UnimplementedError();

  @override
  Future<CashuSendState> checkSendStatus({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) => throw UnimplementedError();

  @override
  Future<CashuAmount> reclaimSend({
    required CashuMintUrl mintUrl,
    required String operationId,
  }) => throw UnimplementedError();
}

final _mintUrl = CashuMintUrl.parse('https://mint.example.com');
