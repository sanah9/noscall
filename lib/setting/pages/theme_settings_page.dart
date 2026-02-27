import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/core/navigation/app_navigator_scope.dart';
import 'package:noscall/setting/services/theme_service.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeService = ThemeService();

    return ValueListenableBuilder<ThemeModeOption>(
      valueListenable: themeService.themeModeNotifier,
      builder: (context, currentMode, _) {
        return ValueListenableBuilder<int>(
          valueListenable: themeService.seedColorValueNotifier,
          builder: (context, seedColorValue, __) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  'Theme',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                  onPressed: () =>
                      AppNavigatorScope.requireOf(context).pop(context),
                ),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildThemeOption(
                      context: context,
                      option: ThemeModeOption.light,
                      title: 'Light',
                      icon: Icons.light_mode,
                      isSelected: currentMode == ThemeModeOption.light,
                      onTap: () =>
                          themeService.setThemeMode(ThemeModeOption.light),
                    ),
                    const SizedBox(height: 8),
                    _buildThemeOption(
                      context: context,
                      option: ThemeModeOption.dark,
                      title: 'Dark',
                      icon: Icons.dark_mode,
                      isSelected: currentMode == ThemeModeOption.dark,
                      onTap: () =>
                          themeService.setThemeMode(ThemeModeOption.dark),
                    ),
                    const SizedBox(height: 8),
                    _buildThemeOption(
                      context: context,
                      option: ThemeModeOption.system,
                      title: 'System',
                      icon: Icons.brightness_auto,
                      isSelected: currentMode == ThemeModeOption.system,
                      onTap: () =>
                          themeService.setThemeMode(ThemeModeOption.system),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Accent color',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: kPresetSeedColors.map((colorValue) {
                        final isSelected = seedColorValue == colorValue;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Center(
                              child: GestureDetector(
                                onTap: () {
                                  themeService.setSeedColorValue(colorValue);
                                },
                                child: _buildColorItem(
                                  colorValue: colorValue,
                                  isSelected: isSelected,
                                  colorScheme: colorScheme,
                                ),
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

  Widget _buildColorItem({
    required int colorValue,
    required bool isSelected,
    required ColorScheme colorScheme,
  }) {
    const cellSize = 44.0;
    const circleSize = 36.0;
    const ringWidth = 3.0;

    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: Center(
        child: isSelected
            ? Container(
                width: circleSize + ringWidth * 2,
                height: circleSize + ringWidth * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary,
                    width: ringWidth,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 6,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(ringWidth),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(colorValue),
                    shape: BoxShape.circle,
                  ),
                ),
              )
            : Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  color: Color(colorValue),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
      ),
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
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
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
