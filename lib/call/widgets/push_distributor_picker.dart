import 'package:flutter/material.dart';

const _knownNames = <String, String>{
  'io.heckel.ntfy': 'ntfy',
  'org.unifiedpush.distributor.nextpush': 'NextPush',
  'eu.siacs.conversations': 'Conversations',
  'org.unifiedpush.distributor.fcm': 'FCM Distributor',
};

String distributorDisplayName(String pkg) =>
    _knownNames[pkg] ?? pkg.split('.').last;

/// Shows a bottom-sheet listing [distributors] and returns the user's pick,
/// or null if the user dismissed without choosing.
Future<String?> showDistributorPicker(
  BuildContext context,
  List<String> distributors,
) {
  return showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _DistributorPickerSheet(distributors: distributors),
  );
}

/// Shows an informational dialog when no UnifiedPush distributors are found.
Future<void> showNoDistributorDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Push notifications'),
      content: const Text(
        'No push notification provider found.\n\n'
        'Install a UnifiedPush distributor app such as ntfy '
        'to receive call notifications when the app is in the background.\n\n'
        'You can find more information at unifiedpush.org',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

class _DistributorPickerSheet extends StatelessWidget {
  const _DistributorPickerSheet({required this.distributors});

  final List<String> distributors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select push notification provider',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          for (final distributor in distributors)
            ListTile(
              title: Text(distributorDisplayName(distributor)),
              subtitle: Text(
                distributor,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              leading: const Icon(Icons.notifications_active_outlined),
              onTap: () => Navigator.of(context).pop(distributor),
            ),
          const Divider(height: 1),
          ListTile(
            title: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            leading: const Icon(Icons.close),
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
