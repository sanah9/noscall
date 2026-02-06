import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class ThemeDialog extends StatelessWidget {
  const ThemeDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ThemeDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeService = ThemeService();

    return ValueListenableBuilder<ThemeModeOption>(
      valueListenable: themeService.themeModeNotifier,
      builder: (context, currentMode, _) {
        return ValueListenableBuilder<int>(
          valueListenable: themeService.seedColorValueNotifier,
          builder: (context, seedColorValue, __) {
            return AlertDialog(
              title: Text(
                'Theme',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildThemeOption(
                context: context,
                option: ThemeModeOption.light,
                title: 'Light',
                icon: Icons.light_mode,
                isSelected: currentMode == ThemeModeOption.light,
                onTap: () {
                  themeService.setThemeMode(ThemeModeOption.light);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 8),
              _buildThemeOption(
                context: context,
                option: ThemeModeOption.dark,
                title: 'Dark',
                icon: Icons.dark_mode,
                isSelected: currentMode == ThemeModeOption.dark,
                onTap: () {
                  themeService.setThemeMode(ThemeModeOption.dark);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 8),
              _buildThemeOption(
                context: context,
                option: ThemeModeOption.system,
                title: 'System',
                icon: Icons.brightness_auto,
                isSelected: currentMode == ThemeModeOption.system,
                onTap: () {
                  themeService.setThemeMode(ThemeModeOption.system);
                  Navigator.of(context).pop();
                },
              ),
                    const SizedBox(height: 20),
                    Text(
                      'Accent color',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: kPresetSeedColors.map((colorValue) {
                        final isSelected = seedColorValue == colorValue;
                        return GestureDetector(
                          onTap: () {
                            themeService.setSeedColorValue(colorValue);
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(colorValue),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline.withValues(alpha: 0.3),
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required ThemeModeOption option,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
