import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/wallet/application/mint_management_controller.dart';
import 'package:noscall/wallet/application/mint_registry_service.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/cashu_models.dart';
import 'package:noscall/wallet/domain/mint_configuration.dart';
import 'package:noscall/wallet/domain/wallet_configuration.dart';
import 'package:noscall/wallet/pages/mint_management_page.dart';

void main() {
  testWidgets('validates and confirms a manually entered Mint', (tester) async {
    final controller = _FakeMintManagementController();
    await tester.pumpWidget(
      MaterialApp(
        home: MintManagementPage(controllerFactory: () async => controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No Mint configured'), findsOneWidget);
    await tester.tap(find.text('Add Mint'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'https://mint.example.com');
    await tester.tap(find.text('Validate'));
    await tester.pumpAndSettle();

    expect(find.text('Test Mint'), findsOneWidget);
    expect(find.textContaining('Trust warning:'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Add Mint'));
    await tester.pumpAndSettle();

    expect(controller.validatedInput, 'https://mint.example.com');
    expect(controller.confirmCalls, 1);
    expect(find.text('No Mint configured'), findsNothing);
    expect(find.text('Test Mint'), findsOneWidget);
  });

  testWidgets('disables and removes a configured Mint after confirmation', (
    tester,
  ) async {
    final controller = _FakeMintManagementController(withMint: true);
    await tester.pumpWidget(
      MaterialApp(
        home: MintManagementPage(controllerFactory: () async => controller),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(controller.enabledChanges, [false]);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();

    expect(controller.removeCalls, 1);
    expect(find.text('No Mint configured'), findsOneWidget);
  });

  testWidgets('shows local Mint balance and disables removal while nonzero', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = _FakeMintManagementController(
      withMint: true,
      balanceSats: 42,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MintManagementPage(controllerFactory: () async => controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('42 sat'), findsOneWidget);
    final removeButton = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('Empty balance to remove'),
        matching: find.byWidgetPredicate((widget) => widget is TextButton),
      ),
    );
    expect(removeButton.onPressed, isNull);
  });
}

final class _FakeMintManagementController implements MintManagementController {
  _FakeMintManagementController({bool withMint = false, this.balanceSats = 0})
    : _mints = withMint ? [_configuration(enabled: true)] : [];

  List<MintConfiguration> _mints;
  String? validatedInput;
  int confirmCalls = 0;
  int removeCalls = 0;
  final List<bool> enabledChanges = [];
  final int balanceSats;

  MintManagementSnapshot get _snapshot => MintManagementSnapshot(
    mints: _mints,
    suggestions: const [],
    balancesSats: {_url: balanceSats},
  );

  @override
  Future<MintManagementSnapshot> load() async => _snapshot;

  @override
  Future<MintRegistrationPreview> validateManual(String input) async {
    validatedInput = input;
    return _preview;
  }

  @override
  Future<MintRegistrationPreview> validateSuggestion(
    DefaultMintSuggestion suggestion,
  ) async => _preview;

  @override
  Future<MintManagementSnapshot> confirm(
    MintRegistrationPreview preview,
  ) async {
    confirmCalls++;
    _mints = [_configuration(enabled: true)];
    return _snapshot;
  }

  @override
  Future<MintManagementSnapshot> setEnabled(
    CashuMintUrl url,
    bool enabled,
  ) async {
    enabledChanges.add(enabled);
    _mints = [_configuration(enabled: enabled)];
    return _snapshot;
  }

  @override
  Future<MintManagementSnapshot> refresh(CashuMintUrl url) async => _snapshot;

  @override
  Future<MintManagementSnapshot> remove(CashuMintUrl url) async {
    removeCalls++;
    _mints = [];
    return _snapshot;
  }

  @override
  Future<void> dispose() async {}
}

final _owner = CashuAccountId.fromNostrPubkey('a' * 64);
final _url = CashuMintUrl.parse('https://mint.example.com');
final _nuts = {
  CashuNut.nut00,
  CashuNut.nut01,
  CashuNut.nut02,
  CashuNut.nut03,
  CashuNut.nut06,
  CashuNut.nut07,
  CashuNut.nut09,
};

final _preview = MintRegistrationPreview(
  owner: _owner,
  snapshot: CashuMintSnapshot(
    url: _url,
    name: 'Test Mint',
    description: 'Test description',
    supportedNuts: _nuts,
    supportsSat: true,
    supportsBolt11Mint: false,
    supportsBolt11Melt: false,
  ),
  capabilities: MintCapabilityDecision(
    canUseCashu: true,
    canMintBolt11: false,
    canMeltBolt11: false,
    missingCoreNuts: const {},
  ),
  source: MintConfigurationSource.manual,
  enabledByDefault: true,
);

MintConfiguration _configuration({required bool enabled}) => MintConfiguration(
  owner: _owner,
  url: _url,
  name: 'Test Mint',
  description: 'Test description',
  enabled: enabled,
  source: MintConfigurationSource.manual,
  supportedNuts: _nuts,
  units: const ['sat'],
  lastSyncAt: DateTime.utc(2026, 6, 21),
);
