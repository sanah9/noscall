import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/setting/services/accessibility_service.dart';

class AccessibilitySettingsPage extends StatelessWidget {
  const AccessibilitySettingsPage({super.key});

  static const List<double?> kTextScaleOptions = [
    null, // system default
    1.0,
    1.1,
    1.2,
    1.3,
    1.4,
  ];

  static String _label(double? value) {
    if (value == null) return 'System default';
    return '${(value * 100).round()}%';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final service = AccessibilityService();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Accessibility',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Font size',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ValueListenableBuilder<double?>(
            valueListenable: service.textScaleFactorNotifier,
            builder: (context, current, _) {
              return Column(
                children: kTextScaleOptions.map((value) {
                  return RadioListTile<double?>(
                    secondary: Icon(
                      Icons.text_fields,
                      color: colorScheme.primary,
                    ),
                    title: Text(
                      _label(value),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    value: value,
                    groupValue: current,
                    onChanged: (v) => service.setTextScaleFactor(v),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
