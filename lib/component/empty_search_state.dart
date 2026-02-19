import 'package:flutter/material.dart';

/// Shared empty state for "no search results" with icon, title and optional subtitle.
/// Use in contacts, group contacts, desktop contacts, recent calls, etc.
class EmptySearchState extends StatelessWidget {
  const EmptySearchState({
    super.key,
    this.icon = Icons.search_off,
    this.title = 'No results found',
    this.subtitle = 'Try a different search term',
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
