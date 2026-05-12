import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/auth/signin_page.dart';

import '../widget_test_helpers.dart';

void main() {
  Future<void> pumpSignInPage(WidgetTester tester) async {
    await pumpRouterApp(
      tester,
      initialLocation: '/signin',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const PlaceholderPage('Login Home Page'),
        ),
        GoRoute(
          path: '/signin',
          builder: (context, state) => const SignInPage(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const PlaceholderPage('Home Page'),
        ),
      ],
    );
  }

  testWidgets('SignInPage renders sign in form', (WidgetTester tester) async {
    await pumpSignInPage(tester);

    expect(find.text('Sign In'), findsNWidgets(2));
    expect(find.text('Powered by Nostr Protocol'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('SignInPage validates empty input on submit', (
    WidgetTester tester,
  ) async {
    await pumpSignInPage(tester);

    final signInButton = find.text('Sign In').last;
    await tester.tap(signInButton);
    await tester.pump();

    expect(
      find.text('Please enter your private key or Bunker URL'),
      findsOneWidget,
    );
  });

  testWidgets('SignInPage toggles visibility and clears input', (
    WidgetTester tester,
  ) async {
    await pumpSignInPage(tester);

    const privateKey = 'nsec1exampleprivatekey';
    final input = find.byType(TextFormField);
    await tester.enterText(input, privateKey);
    await tester.pump();

    EditableText editableText = tester.widget(find.byType(EditableText));
    expect(editableText.obscureText, isTrue);

    await tester.tap(find.byTooltip('Show key'));
    await tester.pump();

    editableText = tester.widget(find.byType(EditableText));
    expect(editableText.obscureText, isFalse);

    await tester.tap(find.byTooltip('Clear'));
    await tester.pump();

    final field = tester.widget<TextFormField>(input);
    expect(field.controller?.text, isEmpty);
  });

  testWidgets('SignInPage back button navigates to login home', (
    WidgetTester tester,
  ) async {
    await pumpSignInPage(tester);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Login Home Page'), findsOneWidget);
  });
}
