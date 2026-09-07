import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/navigation/app_navigator.dart';
import 'package:noscall/core/navigation/app_navigator_scope.dart';
import 'package:noscall/core/navigation/navigation_scope.dart';
import 'package:noscall/desktop/desktop_settings_page.dart';

import '../../helpers/test_data.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late Account account;

  setUp(() {
    account = Account.sharedInstance;
    account.me = null;
    account.currentPubkey = '';
    account.currentPrivkey = '';
    account.userCache.clear();
  });

  tearDown(() {
    account.me = null;
    account.currentPubkey = '';
    account.currentPrivkey = '';
    account.userCache.clear();
  });

  testWidgets('DesktopSettingsPage exposes wallet and paid call entries', (
    tester,
  ) async {
    final user = TestHelpers.createTestUser(
      pubKey: TestData.validPubkey,
      name: 'Alice',
    );
    final navigator = _RecordingNavigator();
    account.me = user;
    account.currentPubkey = user.pubKey;
    account.currentPrivkey = 'test-private-key';
    account.updateOrCreateUserNotifier(user.pubKey, user);

    await tester.pumpWidget(
      MaterialApp(
        home: AppNavigatorScope(
          navigator: navigator,
          child: const DesktopSettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Paid Calls'), findsOneWidget);

    await tester.tap(find.text('Wallet'));
    await tester.tap(find.text('Paid Calls'));

    expect(navigator.walletPushes, 1);
    expect(navigator.callPaymentSettingsPushes, 1);
  });
}

final class _RecordingNavigator extends AppNavigator {
  int walletPushes = 0;
  int callPaymentSettingsPushes = 0;

  @override
  void pushWallet(
    BuildContext context, {
    NavigationScope scope = NavigationScope.automatic,
  }) {
    walletPushes++;
  }

  @override
  void pushCallPaymentSettings(
    BuildContext context, {
    NavigationScope scope = NavigationScope.automatic,
  }) {
    callPaymentSettingsPushes++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
