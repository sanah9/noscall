import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_core_dart/nostr.dart';
import '../../core/account/account.dart';
import '../../utils/toast.dart';
import '../../utils/modal_dialog.dart';

class KeysDialog extends StatelessWidget {
  KeysDialog({super.key});

  late ThemeData theme;
  final FontWeight fontWeight = FontWeight.w500;
  Color get primary => theme.colorScheme.primary;
  Color get primaryContainer => theme.colorScheme.primaryContainer.withValues(alpha: 0.3);
  Color get onPrimaryContainer => theme.colorScheme.onPrimaryContainer;
  Color get onSurface => theme.colorScheme.onSurface;
  Color get onSurfaceVariant => theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
  Color get borderColor => theme.colorScheme.outline.withValues(alpha: 0.1);

  static void show(BuildContext context) {
    AppModalDialog.showStandardDialog(
      context: context,
      headerIcon: Icons.key,
      title: 'Your Keys',
      content: KeysDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    final account = Account.sharedInstance;
    final npub = Nip19.encodePubkey(account.currentPubkey);
    final nsec = Nip19.encodePrivkey(account.currentPrivkey);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPublicKeySection(context, npub),
          Container(
            height: 1,
            color: onSurfaceVariant,
            margin: const EdgeInsets.symmetric(vertical: 20),
          ),
          _buildPrivateKeySection(context, nsec),
        ],
      ),
    );
  }

  Widget _buildPublicKeySection(BuildContext context, String npub) {
    final color = Colors.green.shade700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildShieldIcon(color),
            const SizedBox(width: 8),
            _buildItemTitle('Public Key'),
            const SizedBox(width: 8),
            _buildTitleHint('Safe to share', color),
          ],
        ),
        const SizedBox(height: 12),
        _buildValueCopyWidget(
          value: npub,
          onTap: () {
            Clipboard.setData(ClipboardData(text: npub));
            AppToast.showSuccess(context, 'Public key copied to clipboard');
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Sharing this public key allows others to add you and start calls',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPrivateKeySection(BuildContext context, String privateKey) {
    final color = Colors.red.shade700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildShieldIcon(color),
            const SizedBox(width: 8),
            _buildItemTitle('Private Key'),
            const SizedBox(width: 8),
            _buildTitleHint('Keep secret', color),
          ],
        ),
        const SizedBox(height: 12),

        if (privateKey.isNotEmpty)
          Column(
            children: [
              _buildValueCopyWidget(
                value: privateKey,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: privateKey));
                  AppToast.showSuccess(context, 'Private key copied to clipboard');
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300, width: 1.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Never share your private key with anyone. You could lose access to your account.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.yellow.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade400, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Login with external signer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your private key is managed externally and cannot be displayed in the app.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildShieldIcon(Color color) {
    return Icon(
      Icons.shield_outlined,
      color: color,
      size: 20,
    );
  }

  Widget _buildItemTitle(String text) {
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: onSurface,
        fontWeight: fontWeight,
      ),
    );
  }

  Widget _buildTitleHint(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: fontWeight,
        ),
      ),
    );
  }

  Widget _buildValueCopyWidget({
    required String value,
    required GestureTapCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primaryContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.copy,
              color: primary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}