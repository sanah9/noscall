import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/auth/login_home_page.dart';

import '../widget_test_helpers.dart';

void main() {
  testWidgets('LoginHomePage renders primary actions', (
    WidgetTester tester,
  ) async {
    await pumpRouterApp(
      tester,
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginHomePage(),
        ),
        GoRoute(
          path: '/signin',
          builder: (context, state) => const PlaceholderPage('Sign In Page'),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const PlaceholderPage('Sign Up Page'),
        ),
      ],
    );

    expect(find.text('NosCall'), findsOneWidget);
    expect(find.text('Secure Audio and Video Calls'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Already have account?'), findsOneWidget);
  });

  testWidgets('LoginHomePage navigates to signup', (
    WidgetTester tester,
  ) async {
    await pumpRouterApp(
      tester,
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginHomePage(),
        ),
        GoRoute(
          path: '/signin',
          builder: (context, state) => const PlaceholderPage('Sign In Page'),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const PlaceholderPage('Sign Up Page'),
        ),
      ],
    );

    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Sign Up Page'), findsOneWidget);
  });

  testWidgets('LoginHomePage navigates to signin', (
    WidgetTester tester,
  ) async {
    await pumpRouterApp(
      tester,
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginHomePage(),
        ),
        GoRoute(
          path: '/signin',
          builder: (context, state) => const PlaceholderPage('Sign In Page'),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const PlaceholderPage('Sign Up Page'),
        ),
      ],
    );

    await tester.tap(find.text('Already have account?'));
    await tester.pumpAndSettle();

    expect(find.text('Sign In Page'), findsOneWidget);
  });
}
