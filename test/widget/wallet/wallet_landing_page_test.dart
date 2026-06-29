import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/wallet/application/wallet_landing_controller.dart';
import 'package:noscall/wallet/domain/wallet_configuration.dart';
import 'package:noscall/wallet/pages/wallet_backup_page.dart';
import 'package:noscall/wallet/pages/wallet_landing_page.dart';

void main() {
  testWidgets('shows development setup without a default Mint', (tester) async {
    final controller = _FakeLandingController();

    await tester.pumpWidget(
      MaterialApp(
        home: WalletLandingPage(controllerFactory: () async => controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Development wallet'), findsOneWidget);
    expect(find.text('Create wallet'), findsOneWidget);
    expect(find.text('Restore wallet'), findsOneWidget);
    expect(
      find.textContaining('does not provide a default Mint'),
      findsOneWidget,
    );
  });

  testWidgets('creates a wallet and allows backup to be skipped', (
    tester,
  ) async {
    final controller = _FakeLandingController();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              WalletLandingPage(controllerFactory: () async => controller),
        ),
        GoRoute(
          path: '/wallet/backup',
          builder: (context, state) {
            final arguments = state.extra! as WalletBackupArguments;
            return WalletBackupPage(mnemonic: arguments.mnemonic);
          },
        ),
        GoRoute(
          path: '/wallet/mints',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/wallet/receive-token',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/wallet/receive-lightning',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/wallet/send-token',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/wallet/pay-lightning',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create wallet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Write down these 12 words in order'), findsOneWidget);
    expect(find.text('abandon'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back up later'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Back up later'));
    await tester.pumpAndSettle();

    expect(controller.backupStatuses, [
      WalletBackupStatus.shown,
      WalletBackupStatus.skipped,
    ]);
    expect(find.text('0 sat'), findsOneWidget);
    expect(find.text('No Mint configured'), findsOneWidget);
    expect(find.text('Wallet backup is not complete'), findsOneWidget);
  });

  testWidgets('shows token actions for a funded wallet with enabled Mint', (
    tester,
  ) async {
    final controller = _FakeLandingController(
      created: true,
      backupStatus: WalletBackupStatus.confirmed,
      balanceSats: 50,
      mintCount: 1,
      enabledMintCount: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WalletLandingPage(controllerFactory: () async => controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Receive Lightning'), findsOneWidget);
    expect(find.text('Receive token'), findsOneWidget);
    expect(find.text('Pay Lightning'), findsOneWidget);
    expect(find.text('Send token'), findsOneWidget);
  });
}

final class _FakeLandingController implements WalletLandingController {
  static const mnemonic =
      'abandon ability able about above absent absorb abstract absurd abuse access accident';

  _FakeLandingController({
    this.created = false,
    this.backupStatus,
    this.balanceSats = 0,
    this.mintCount = 0,
    this.enabledMintCount = 0,
  });

  bool created;
  WalletBackupStatus? backupStatus;
  final int balanceSats;
  final int mintCount;
  final int enabledMintCount;
  final List<WalletBackupStatus> backupStatuses = [];

  @override
  bool get isDevelopmentOnly => true;

  @override
  Future<String> createWallet() async {
    created = true;
    return mnemonic;
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<void> closeSession() async {}

  @override
  Future<WalletLandingSnapshot> load() async {
    if (!created) return const WalletLandingSnapshot.absent();
    return WalletLandingSnapshot.ready(
      balanceSats: balanceSats,
      backupStatus: backupStatus ?? WalletBackupStatus.notShown,
      mintCount: mintCount,
      enabledMintCount: enabledMintCount,
    );
  }

  @override
  Future<WalletLandingSnapshot> updateBackupStatus(
    WalletBackupStatus status,
  ) async {
    backupStatus = status;
    backupStatuses.add(status);
    return load();
  }
}
