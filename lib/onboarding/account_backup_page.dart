import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_core_dart/nostr.dart';

class AccountBackupPage extends StatefulWidget {
  const AccountBackupPage({super.key, required this.privateKey});
  final String privateKey;

  @override
  State<AccountBackupPage> createState() => _AccountBackupPageState();
}

class _AccountBackupPageState extends State<AccountBackupPage>
    with WidgetsBindingObserver {
  bool _revealed = false;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) {
      setState(() => _revealed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final external = widget.privateKey.isEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Account backup')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Icon(
                external ? Icons.key_outlined : Icons.lock_outline,
                size: 48,
              ),
              const SizedBox(height: 24),
              Text(
                external
                    ? 'Back up your external signer'
                    : 'Keep your private key safe',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                external
                    ? 'Your key is managed by your signer. Confirm that you can recover access there.'
                    : 'Anyone with this key can access your account. Keep an offline backup. This key does not replace your wallet recovery words.',
              ),
              const SizedBox(height: 24),
              if (!external) ...[
                if (_revealed)
                  SelectableText(Nip19.encodePrivkey(widget.privateKey)),
                Row(
                  children: [
                    IconButton(
                      tooltip: _revealed
                          ? 'Hide private key'
                          : 'Reveal private key',
                      onPressed: () => setState(() => _revealed = !_revealed),
                      icon: Icon(
                        _revealed ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                    if (_revealed)
                      IconButton(
                        tooltip: 'Copy private key',
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(
                              text: Nip19.encodePrivkey(widget.privateKey),
                            ),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Private key copied'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy),
                      ),
                  ],
                ),
              ],
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _confirmed,
                onChanged: (value) =>
                    setState(() => _confirmed = value ?? false),
                title: Text(
                  external
                      ? 'I can recover my signer account'
                      : 'I have a safe backup of my account key',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _confirmed
                    ? () => Navigator.of(context).pop(true)
                    : null,
                icon: const Icon(Icons.check),
                label: const Text('Confirm backup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
