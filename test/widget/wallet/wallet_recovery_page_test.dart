import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/application/wallet_recovery_input_controller.dart';
import 'package:noscall/wallet/pages/wallet_recovery_page.dart';

void main() {
  const mnemonic =
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

  testWidgets('reviews valid recovery details without executing recovery', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WalletRecoveryPage(
          controller: WalletRecoveryInputController(
            mnemonicValidator: _Validator(valid: true),
          ),
        ),
      ),
    );

    expect(find.text('Recovery execution is not enabled yet'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), mnemonic);
    await tester.enterText(
      find.byType(TextField).at(1),
      'https://mint.example.com\nhttps://other.example.com',
    );
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review recovery details'));
    await tester.pumpAndSettle();

    expect(find.text('Recovery details are valid'), findsOneWidget);
    expect(find.textContaining('2 Mint URLs'), findsOneWidget);
    expect(find.textContaining('were not saved'), findsOneWidget);
  });

  testWidgets('shows a safe validation error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WalletRecoveryPage(
          controller: WalletRecoveryInputController(
            mnemonicValidator: _Validator(valid: false),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), mnemonic);
    await tester.enterText(
      find.byType(TextField).at(1),
      'https://mint.example.com',
    );
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review recovery details'));
    await tester.pump();

    expect(
      find.text('Enter a valid 12-word wallet recovery phrase.'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.textContaining('abandon abandon'),
      ),
      findsNothing,
    );
  });
}

final class _Validator implements WalletMnemonicValidator {
  const _Validator({required this.valid});

  final bool valid;

  @override
  bool isValidTwelveWordMnemonic(String mnemonic) => valid;
}
