import 'package:go_router/go_router.dart';
import 'package:noscall/auth/auth_service.dart';
import 'package:noscall/onboarding/onboarding_service.dart';
import 'package:noscall/utils/routes/auth_routes.dart';
import 'package:noscall/utils/routes/call_payment_routes.dart';
import 'package:noscall/utils/routes/call_routes.dart';
import 'package:noscall/utils/routes/contacts_routes.dart';
import 'package:noscall/utils/routes/settings_routes.dart';
import 'package:noscall/utils/routes/voice_routes.dart';
import 'package:noscall/utils/routes/wallet_routes.dart';

export 'router_utils.dart';

class AppRouter {
  static final _router = GoRouter(
    initialLocation: _initialLocation,
    routes: [
      ...authRoutes,
      ...callPaymentRoutes,
      ...callRoutes,
      ...contactsRoutes,
      ...settingsRoutes,
      ...voiceRoutes,
      ...walletRoutes,
    ],
  );

  static GoRouter get router => _router;

  static String get _initialLocation {
    if (AuthService().isAuthenticated) return '/';
    if (!OnboardingService().isCompleted) return '/onboarding';
    return '/login';
  }
}
