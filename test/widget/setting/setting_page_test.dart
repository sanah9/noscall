import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/setting/setting_page.dart';

import '../../helpers/test_data.dart';
import '../../helpers/test_helpers.dart';
import '../widget_test_helpers.dart';

void main() {
  late ConnectivityPlatform originalConnectivityPlatform;
  late Account account;

  setUp(() {
    originalConnectivityPlatform = ConnectivityPlatform.instance;
    ConnectivityPlatform.instance = FakeConnectivityPlatform(
      initialResults: const [ConnectivityResult.wifi],
    );
    account = Account.sharedInstance;
    account.me = null;
    account.currentPubkey = '';
    account.currentPrivkey = '';
    account.userCache.clear();
  });

  tearDown(() {
    ConnectivityPlatform.instance = originalConnectivityPlatform;
    account.me = null;
    account.currentPubkey = '';
    account.currentPrivkey = '';
    account.userCache.clear();
  });

  testWidgets('SettingPage shows error state without authenticated user', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No user data found'), findsOneWidget);
    expect(find.text('Please log in again'), findsOneWidget);
    expect(find.text('Go to Login'), findsOneWidget);
  });

  testWidgets('SettingPage renders profile menu for authenticated user', (
    WidgetTester tester,
  ) async {
    final user = TestHelpers.createTestUser(
      pubKey: TestData.validPubkey,
      name: 'Alice',
    );
    account.me = user;
    account.currentPubkey = user.pubKey;
    account.currentPrivkey = 'test-private-key';
    account.updateOrCreateUserNotifier(user.pubKey, user);

    await tester.pumpWidget(
      const MaterialApp(
        home: SettingPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Network'), findsOneWidget);
    expect(find.text('WiFi'), findsOneWidget);
    expect(find.text('Account & Security'), findsOneWidget);
    expect(find.text('Connection'), findsOneWidget);
    expect(find.text('Appearance & Notifications'), findsOneWidget);
    expect(find.text('Data'), findsOneWidget);
    expect(find.text('About & Debug'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });
}
