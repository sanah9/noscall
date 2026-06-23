import 'package:flutter/material.dart';

import '../domain/wallet_configuration.dart';

final class WalletBackupArguments {
  const WalletBackupArguments(this.mnemonic);

  final String mnemonic;
}

final class WalletBackupPage extends StatefulWidget {
  const WalletBackupPage({super.key, required this.mnemonic});

  final String mnemonic;

  @override
  State<WalletBackupPage> createState() => _WalletBackupPageState();
}

final class _WalletBackupPageState extends State<WalletBackupPage> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final words = widget.mnemonic.trim().split(RegExp(r'\s+'));
    return Scaffold(
      appBar: AppBar(title: const Text('Back up wallet')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Write down these 12 words in order',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Anyone with these words can spend your funds. Do not share them or store them in chat, screenshots, or cloud notes.',
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: words.length,
              itemBuilder: (context, index) => DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Text('${index + 1}.'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          words[index],
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _confirmed,
              onChanged: (value) => setState(() => _confirmed = value ?? false),
              title: const Text('I saved these words in a safe place'),
            ),
            FilledButton(
              onPressed: _confirmed
                  ? () =>
                        Navigator.of(context).pop(WalletBackupStatus.confirmed)
                  : null,
              child: const Text('Finish backup'),
            ),
            TextButton(
              onPressed: () => _confirmSkip(context),
              child: const Text('Back up later'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSkip(BuildContext context) async {
    final shouldSkip = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Back up later?'),
        content: const Text(
          'If this device is lost before you back up, the wallet and its funds may be impossible to recover.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep backing up'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Back up later'),
          ),
        ],
      ),
    );
    if (shouldSkip == true && context.mounted) {
      Navigator.of(context).pop(WalletBackupStatus.skipped);
    }
  }
}
