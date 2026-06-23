import 'package:flutter/material.dart';

import '../application/wallet_recovery_input_controller.dart';
import '../infrastructure/cdk/cdk_wallet_mnemonic_validator.dart';

final class WalletRecoveryPage extends StatefulWidget {
  const WalletRecoveryPage({super.key, this.controller});

  final WalletRecoveryInputController? controller;

  @override
  State<WalletRecoveryPage> createState() => _WalletRecoveryPageState();
}

final class _WalletRecoveryPageState extends State<WalletRecoveryPage> {
  late final TextEditingController _mnemonicController;
  late final TextEditingController _mintUrlsController;
  late final WalletRecoveryInputController _controller;
  bool _reviewing = false;

  @override
  void initState() {
    super.initState();
    _mnemonicController = TextEditingController();
    _mintUrlsController = TextEditingController();
    _controller =
        widget.controller ??
        const WalletRecoveryInputController(
          mnemonicValidator: CdkWalletMnemonicValidator(),
        );
  }

  @override
  void dispose() {
    _mnemonicController.dispose();
    _mintUrlsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restore wallet')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Recovery details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Enter the independent 12-word Cashu wallet phrase. Never enter your Nostr private key or account recovery phrase here.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mnemonicController,
              minLines: 3,
              maxLines: 5,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: '12-word wallet recovery phrase',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Cashu cannot discover all previously used Mints from the phrase alone. Add every Mint you remember, one HTTPS URL per line.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _mintUrlsController,
              minLines: 3,
              maxLines: 6,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Previously used Mint URLs',
                hintText: 'https://mint.example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: const ListTile(
                leading: Icon(Icons.construction_outlined),
                title: Text('Recovery execution is not enabled yet'),
                subtitle: Text(
                  'This development step validates details locally and stores nothing. Asset recovery will be enabled after per-Mint NUT-09/NUT-13 results and idempotency handling are complete.',
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _reviewing ? null : _review,
              child: const Text('Review recovery details'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _review() async {
    setState(() => _reviewing = true);
    try {
      final draft = _controller.validate(
        mnemonicInput: _mnemonicController.text,
        mintUrlsInput: _mintUrlsController.text,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Recovery details are valid'),
          content: Text(
            '${draft.mintUrls.length} Mint URL${draft.mintUrls.length == 1 ? '' : 's'} ready for the future recovery step. The phrase and URLs were not saved.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } on WalletRecoveryInputException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _reviewing = false);
    }
  }
}
