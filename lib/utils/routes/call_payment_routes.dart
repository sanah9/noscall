import 'package:go_router/go_router.dart';
import 'package:noscall/call_payments/pages/call_payment_settings_page.dart';

List<RouteBase> get callPaymentRoutes => [
  GoRoute(
    path: '/call-payments/settings',
    name: 'call-payment-settings',
    builder: (context, state) => const CallPaymentSettingsPage(),
  ),
];
