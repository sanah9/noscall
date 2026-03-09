import 'package:go_router/go_router.dart';

import 'package:noscall/auth/login_home_page.dart';
import 'package:noscall/auth/signin_page.dart';
import 'package:noscall/auth/signup_page.dart';
import 'package:noscall/auth/account_info_page.dart';
import 'package:noscall/home/home_page.dart';

/// Auth and home routes: login, signin, signup, account-info, home.
List<RouteBase> get authRoutes => [
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
    ];
