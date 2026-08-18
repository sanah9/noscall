import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/pages/call_payment_confirm_page.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';

void main() {
  testWidgets('shows ordinary token risk copy', (tester) async {
    await _setLargeSurface(tester);
    await tester.pumpWidget(_App(arguments: _arguments()));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Ordinary token payment'), findsOneWidget);
    expect(
      find.textContaining('encrypted ordinary Cashu tokens'),
      findsOneWidget,
    );
    expect(
      find.textContaining('refunds depend on the other client'),
      findsOneWidget,
    );
  });

  testWidgets('validates max spend before confirming', (tester) async {
    await _setLargeSurface(tester);
    CallPaymentConfirmResult? result;
    await tester.pumpWidget(
      _App(
        arguments: _arguments(),
        onResult: (value) {
          result = value;
        },
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '9');
    await _tapConfirm(tester);
    expect(find.text('At least one period is required.'), findsOneWidget);
    expect(result, isNull);

    await tester.enterText(find.byType(TextField), '101');
    await _tapConfirm(tester);
    expect(find.text('Limit cannot exceed Mint balance.'), findsOneWidget);
    expect(result, isNull);

    await tester.enterText(find.byType(TextField), '40');
    await _tapConfirm(tester);
    expect(result?.maxSpendSats, 40);
  });
}

Future<void> _tapConfirm(WidgetTester tester) async {
  await tester.tap(find.text('Confirm and call'));
  await tester.pumpAndSettle();
}

Future<void> _setLargeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(420, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

CallPaymentConfirmArguments _arguments() {
  return CallPaymentConfirmArguments(
    peerPubkey: 'a' * 64,
    peerDisplayName: 'Alice',
    callType: CallPaymentCallType.audio,
    mintUrl: CashuMintUrl.parse('https://mint.example'),
    balanceSats: 100,
    priceSatsPerMinute: 10,
    periodAmountSats: 10,
    billingPeriodSeconds: 60,
    gracePeriodSeconds: 10,
    defaultMaxSpendSats: 30,
  );
}

final class _App extends StatelessWidget {
  const _App({required this.arguments, this.onResult});

  final CallPaymentConfirmArguments arguments;
  final ValueChanged<CallPaymentConfirmResult?>? onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return FilledButton(
            onPressed: () async {
              final result = await Navigator.of(context)
                  .push<CallPaymentConfirmResult>(
                    MaterialPageRoute(
                      builder: (_) =>
                          CallPaymentConfirmPage(arguments: arguments),
                    ),
                  );
              onResult?.call(result);
            },
            child: const Text('Open'),
          );
        },
      ),
    );
  }
}
