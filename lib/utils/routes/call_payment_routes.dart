import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/call_payments/pages/call_payment_confirm_page.dart';
import 'package:noscall/call_payments/pages/call_payment_settings_page.dart';

List<RouteBase> get callPaymentRoutes => [
  GoRoute(
    path: '/call-payments/settings',
    name: 'call-payment-settings',
    builder: (context, state) => const CallPaymentSettingsPage(),
  ),
  GoRoute(
    path: '/call-payments/confirm',
    name: 'call-payment-confirm',
    builder: (context, state) {
      final extra = state.extra;
      if (extra is CallPaymentConfirmArguments) {
        return CallPaymentConfirmPage(arguments: extra);
      }
      return const _MissingCallPaymentConfirmArgumentsPage();
    },
  ),
];

final class _MissingCallPaymentConfirmArgumentsPage extends StatelessWidget {
  const _MissingCallPaymentConfirmArgumentsPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Paid call confirmation is unavailable.')),
    );
  }
}
