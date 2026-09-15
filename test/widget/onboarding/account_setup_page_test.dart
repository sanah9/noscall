import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/onboarding/account_backup_page.dart';
import 'package:noscall/onboarding/account_setup_page.dart';
import 'package:noscall/onboarding/account_setup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('opening backup without confirming does not mark it completed', (
    tester,
  ) async {
    final service = AccountSetupService('a' * 64);
    await tester.pumpWidget(
      MaterialApp(
        home: AccountSetupPage(
          service: service,
          loadFacts: () async => {},
          openStep: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Account key backup'));
    await tester.pumpAndSettle();
    expect(
      (await service.load()).status(AccountSetupStep.backup),
      AccountSetupStatus.pending,
    );
  });

  testWidgets(
    'confirms backup, saves skip, and exits without claiming completion',
    (tester) async {
      final service = AccountSetupService('a' * 64);
      var exited = false;
      await tester.pumpWidget(
        MaterialApp(
          home: AccountSetupPage(
            service: service,
            loadFacts: () async => {AccountSetupStep.profile},
            openStep: (_) async => true,
            onExit: () => exited = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Account key backup'));
      await tester.pumpAndSettle();
      expect((await service.load()).completedCount, 2);
      await tester.tap(find.byTooltip('Skip this step').first);
      await tester.pumpAndSettle();
      expect(
        (await service.load()).status(AccountSetupStep.notifications),
        AccountSetupStatus.skipped,
      );
      await tester.tap(find.byTooltip('Continue later'));
      await tester.pumpAndSettle();
      expect(exited, isTrue);
      expect((await service.load()).dismissed, isTrue);
      expect((await service.load()).completedCount, 2);
    },
  );

  testWidgets('fits a narrow viewport with enlarged text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: AccountSetupPage(
            service: AccountSetupService('a' * 64),
            loadFacts: () async => {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Go to contacts'), 150);
    expect(tester.takeException(), isNull);
  });

  testWidgets('external signer backup never displays a local key', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AccountBackupPage(privateKey: '')),
    );
    expect(find.text('Back up your external signer'), findsOneWidget);
    expect(find.byTooltip('Reveal private key'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.byWidgetPredicate((w) => w is FilledButton),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.byWidgetPredicate((w) => w is FilledButton),
          )
          .onPressed,
      isNotNull,
    );
  });
}
