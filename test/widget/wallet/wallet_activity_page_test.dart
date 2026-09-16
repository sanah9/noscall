import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/application/wallet_activity_service.dart';
import 'package:noscall/wallet/pages/wallet_activity_page.dart';
import '../../helpers/payment_activity_fixtures.dart';

void main() {
  final token = WalletActivityEntry(
    id: 'record-id',
    kind: WalletActivityKind.token,
    title: 'Token received',
    status: 'Received',
    amountSats: 5,
    incoming: true,
    pending: false,
    createdAt: activityTime,
    mintUrl: activityMint,
  );
  testWidgets('filters pending activity and opens safe record details', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WalletActivityPage(
          owner: activityOwner,
          loader: (_) async => [
            token,
            ...WalletActivityService.merge(
              owner: activityOwner,
              calls: [activityCall()],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Token received'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('Token received'), findsNothing);
    expect(find.text('Paid call'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Token received'));
    await tester.pumpAndSettle();
    expect(find.text('record-id'), findsOneWidget);
    expect(find.text('https://mint.example'), findsOneWidget);
  });
  testWidgets('refresh recovers from error and enlarged text fits mobile', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var reads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: WalletActivityPage(
            owner: activityOwner,
            loader: (_) async {
              if (++reads == 1) throw StateError('database');
              return [token];
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Activity could not be loaded.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Token received'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
