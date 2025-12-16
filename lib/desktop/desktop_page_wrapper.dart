import 'package:flutter/material.dart';

class DesktopPageWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? searchBar;
  final List<Widget>? actions;

  const DesktopPageWrapper({
    super.key,
    required this.title,
    required this.child,
    this.searchBar,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 32),
              if (searchBar != null) Expanded(child: searchBar!),
              if (actions != null) ...actions!,
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}