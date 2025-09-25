import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/auth/auth_service.dart';
import 'package:noscall/call/call_ui/calling_page.dart';
import 'package:noscall/call/calling_controller.dart';
import 'package:noscall/call_history/models/call_entry.dart';
import '../auth/login_home_page.dart';
import '../auth/signin_page.dart';
import '../auth/signup_page.dart';
import '../auth/account_info_page.dart';
import '../home/home_page.dart';
import '../contacts/add_contact_page.dart';
import '../contacts/user_detail_page.dart';

class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: AuthService().isAuthenticated ? '/' : '/login',
    routes: [
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
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/account-info',
        name: 'account-info',
        builder: (context, state) => const AccountInfoPage(),
      ),
      GoRoute(
        path: '/call',
        name: 'call',
        builder: (context, state) {
          CallingController controller = state.extra as CallingController;
          return CallingPage(controller: controller);
        },
      ),
      GoRoute(
        path: '/add-contact',
        name: 'add-contact',
        builder: (context, state) => const AddContactPage(),
      ),
      GoRoute(
        path: '/user-detail',
        name: 'user-detail',
        builder: (context, state) {
          final params = state.extra as Map? ?? {};
          final pubkey = params['pubkey'] as String?;
          final callHistory = params['callHistory'] as List<CallEntry>?;
          if (pubkey == null || pubkey.isEmpty) {
            return const Scaffold(
              body: Center(
                child: Text('User pubkey not found'),
              ),
            );
          }
          return UserDetailPage(
            pubkey: pubkey,
            callHistory: callHistory,
          );
        },
      ),
    ],
  );

  static GoRouter get router => _router;
}
