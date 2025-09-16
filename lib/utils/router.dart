import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/auth/auth_service.dart';
import 'package:noscall/call/call_ui/calling_page.dart';
import 'package:noscall/call/calling_controller.dart';
import '../auth/login_page.dart';
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
        builder: (context, state) => const LoginPage(),
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
          final pubkey = state.extra as String?;
          if (pubkey == null) {
            return const Scaffold(
              body: Center(
                child: Text('User pubkey not found'),
              ),
            );
          }
          return UserDetailPage(pubkey: pubkey);
        },
      ),
    ],
  );

  static GoRouter get router => _router;
}
