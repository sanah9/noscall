import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../wallet/pages/wallet_backup_page.dart';
import '../../wallet/pages/wallet_landing_page.dart';
import '../../wallet/pages/mint_management_page.dart';
import '../../wallet/pages/wallet_recovery_page.dart';

List<RouteBase> get walletRoutes => [
  GoRoute(
    path: '/wallet',
    name: 'wallet',
    builder: (context, state) => const WalletLandingPage(),
  ),
  GoRoute(
    path: '/wallet/backup',
    name: 'wallet-backup',
    builder: (context, state) {
      final arguments = state.extra;
      if (arguments is! WalletBackupArguments) {
        return const Scaffold(
          body: Center(child: Text('Wallet backup is unavailable.')),
        );
      }
      return WalletBackupPage(mnemonic: arguments.mnemonic);
    },
  ),
  GoRoute(
    path: '/wallet/restore',
    name: 'wallet-restore',
    builder: (context, state) => const WalletRecoveryPage(),
  ),
  GoRoute(
    path: '/wallet/mints',
    name: 'wallet-mints',
    builder: (context, state) => const MintManagementPage(),
  ),
];
