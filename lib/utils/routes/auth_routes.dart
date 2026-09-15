import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

import 'package:noscall/auth/login_home_page.dart';
import 'package:noscall/auth/signin_page.dart';
import 'package:noscall/auth/signup_page.dart';
import 'package:noscall/auth/account_info_page.dart';
import 'package:noscall/home/home_page.dart';
import 'package:noscall/onboarding/onboarding_page.dart';
import 'package:noscall/onboarding/account_setup_page.dart';
import 'package:noscall/onboarding/account_setup_service.dart';
import 'package:noscall/auth/auth_service.dart';

/// Auth and home routes: login, signin, signup, account-info, home.
List<RouteBase> get authRoutes => [
  GoRoute(
    path: '/onboarding',
    name: 'onboarding',
    builder: (context, state) => const OnboardingPage(),
  ),
  GoRoute(
    path: '/login',
    name: 'login',
    builder: (context, state) => const LoginHomePage(),
  ),
  GoRoute(
    path: '/signin',
    name: 'signin',
    builder: (context, state) => const SignInPage(),
  ),
  GoRoute(
    path: '/signup',
    name: 'signup',
    builder: (context, state) => const SignUpPage(),
  ),
  GoRoute(
    path: '/',
    name: 'home',
    redirect: (context, state) =>
        AuthService().isAuthenticated ? null : '/login',
    builder: (context, state) => AccountSetupGate(
      key: ValueKey(AuthService().currentUserPubkey),
      pubkey: AuthService().currentUserPubkey!,
      child: const HomePage(),
    ),
  ),
  GoRoute(
    path: '/account-setup',
    redirect: (context, state) =>
        AuthService().isAuthenticated ? null : '/login',
    builder: (context, state) => AccountSetupPage(
      service: AccountSetupService(AuthService().currentUserPubkey!),
    ),
  ),
  GoRoute(
    path: '/account-info',
    name: 'account-info',
    builder: (context, state) => const AccountInfoPage(),
  ),
];
