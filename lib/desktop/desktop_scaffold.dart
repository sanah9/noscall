import 'package:flutter/material.dart';
import 'package:noscall/core/call/messages/messages.dart';

class DesktopScaffold extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavigationChanged;

  const DesktopScaffold({
    super.key,
    required this.selectedIndex,
    required this.onNavigationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'noscall',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _NavigationItem(
            icon: Icons.call_outlined,
            selectedIcon: Icons.call,
            label: 'Recent',
            isSelected: selectedIndex == 0,
            onTap: () => onNavigationChanged(0),
          ),
          _NavigationItem(
            icon: Icons.contacts_outlined,
            selectedIcon: Icons.contacts,
            label: 'Contacts',
            isSelected: selectedIndex == 1,
            onTap: () => onNavigationChanged(1),
          ),
          _NavigationItem(
            icon: Icons.folder_outlined,
            selectedIcon: Icons.folder,
            label: 'Groups',
            isSelected: selectedIndex == 2,
            onTap: () => onNavigationChanged(2),
          ),
          ValueListenableBuilder<int>(
            valueListenable: Messages.sharedInstance.voiceUnreadCountNotifier,
            builder: (context, unreadCount, child) {
              return _NavigationItem(
                icon: Icons.mic_none,
                selectedIcon: Icons.mic,
                label: 'Voice',
                isSelected: selectedIndex == 3,
                onTap: () => onNavigationChanged(3),
                badgeCount: unreadCount,
              );
            },
          ),
          _NavigationItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Me',
            isSelected: selectedIndex == 4,
            onTap: () => onNavigationChanged(4),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Badge(
                  isLabelVisible: badgeCount > 0,
                  label: Text('$badgeCount'),
                  child: Icon(
                    isSelected ? selectedIcon : icon,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}