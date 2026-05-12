import 'package:flutter/material.dart';

class AccountInfoKeyDetailsDialog extends StatelessWidget {
  const AccountInfoKeyDetailsDialog({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.copyLabel,
    required this.onCopy,
  });

  final String title;
  final String description;
  final String value;
  final String copyLabel;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: SelectableText(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCopy,
          child: const Text('Copy'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class AccountInfoStatusHeader extends StatelessWidget {
  const AccountInfoStatusHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_circle,
            size: 80,
            color: colorScheme.onPrimary,
          ),
          const SizedBox(height: 16),
          Text(
            'Account Status',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Logged In',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AccountInfoPublicKeySection extends StatelessWidget {
  const AccountInfoPublicKeySection({
    super.key,
    required this.npub,
    required this.pubkey,
    required this.onShowNpubDetails,
    required this.onCopyNpub,
    required this.onShowPubkeyDetails,
    required this.onCopyPubkey,
  });

  final String npub;
  final String pubkey;
  final VoidCallback onShowNpubDetails;
  final VoidCallback onCopyNpub;
  final VoidCallback onShowPubkeyDetails;
  final VoidCallback onCopyPubkey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'Public Key Information',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _AccountInfoKeyTile(
                leadingIcon: Icons.public,
                leadingColor: colorScheme.tertiary,
                title: 'Nostr Public Key (npub)',
                value: npub,
                infoTooltip: 'View Details',
                copyTooltip: 'Copy npub',
                onShowDetails: onShowNpubDetails,
                onCopy: onCopyNpub,
              ),
              Divider(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.1),
                indent: 16,
                endIndent: 16,
              ),
              _AccountInfoKeyTile(
                leadingIcon: Icons.key,
                leadingColor: colorScheme.primary,
                title: 'Raw Public Key',
                value: pubkey,
                infoTooltip: 'View Details',
                copyTooltip: 'Copy Public Key',
                onShowDetails: onShowPubkeyDetails,
                onCopy: onCopyPubkey,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountInfoKeyTile extends StatelessWidget {
  const _AccountInfoKeyTile({
    required this.leadingIcon,
    required this.leadingColor,
    required this.title,
    required this.value,
    required this.infoTooltip,
    required this.copyTooltip,
    required this.onShowDetails,
    required this.onCopy,
  });

  final IconData leadingIcon;
  final Color leadingColor;
  final String title;
  final String value;
  final String infoTooltip;
  final String copyTooltip;
  final VoidCallback onShowDetails;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Icon(leadingIcon, color: leadingColor),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value,
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          color: colorScheme.onSurfaceVariant,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant),
            onPressed: onShowDetails,
            tooltip: infoTooltip,
          ),
          IconButton(
            icon: Icon(Icons.copy, color: colorScheme.primary),
            onPressed: onCopy,
            tooltip: copyTooltip,
          ),
        ],
      ),
    );
  }
}

class AccountInfoActionsSection extends StatelessWidget {
  const AccountInfoActionsSection({
    super.key,
    required this.onRefresh,
    required this.onLogout,
  });

  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'Account Actions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.refresh, color: colorScheme.primary),
                title: Text(
                  'Refresh Account Info',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Reload your account information',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: colorScheme.onSurfaceVariant,
                ),
                onTap: onRefresh,
              ),
              Divider(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.1),
                indent: 16,
                endIndent: 16,
              ),
              ListTile(
                leading: Icon(Icons.logout, color: colorScheme.error),
                title: Text(
                  'Logout',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.error,
                  ),
                ),
                subtitle: Text(
                  'Sign out of your account',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: colorScheme.onSurfaceVariant,
                ),
                onTap: onLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AccountInfoAboutSection extends StatelessWidget {
  const AccountInfoAboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'About Your Account',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Your npub is your public identifier that others can use to call you\n'
            '• Your raw public key is the internal representation used by the app\n'
            '• Keep your private key secure and never share it with anyone\n'
            '• You can share your npub with trusted contacts to receive calls',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
