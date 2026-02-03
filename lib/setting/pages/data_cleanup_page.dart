import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/call/call_manager.dart';
import 'package:noscall/setting/services/data_cleanup_service.dart';
import '../../utils/toast.dart';

class DataCleanupPage extends StatefulWidget {
  const DataCleanupPage({super.key});

  @override
  State<DataCleanupPage> createState() => _DataCleanupPageState();
}

class _DataCleanupPageState extends State<DataCleanupPage> {
  static const List<int> _oldDataDaysOptions = [30, 90, 180];
  int _selectedDays = 90;
  bool _clearingCache = false;
  bool _clearingOldData = false;

  Future<void> _clearCache() async {
    if (_clearingCache) return;
    setState(() => _clearingCache = true);
    try {
      final result = await DataCleanupService.instance.clearCache();
      if (mounted) {
        if (result.success) {
          AppToast.showSuccess(context, result.message);
        } else {
          AppToast.showError(context, result.message);
        }
      }
    } finally {
      if (mounted) setState(() => _clearingCache = false);
    }
  }

  Future<void> _clearOldData() async {
    if (_clearingOldData) return;
    setState(() => _clearingOldData = true);
    try {
      final callHistoryManager = CallKitManager.instance.callHistoryManager;
      final result = await DataCleanupService.instance.clearOldData(
        days: _selectedDays,
        callHistoryManager: callHistoryManager,
      );
      if (mounted) {
        if (result.success) {
          AppToast.showSuccess(context, result.message);
        } else {
          AppToast.showError(context, result.message);
        }
      }
    } finally {
      if (mounted) setState(() => _clearingOldData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data cleanup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          _SectionHeader(
            icon: Icons.folder_off,
            title: 'Clear cache',
            subtitle: 'Clears image cache (e.g. avatars). Does not delete call history or settings.',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _clearingCache ? null : _clearCache,
              icon: _clearingCache
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.cleaning_services),
              label: Text(_clearingCache ? 'Clearing...' : 'Clear cache'),
            ),
          ),
          const SizedBox(height: 32),
          _SectionHeader(
            icon: Icons.history_edu,
            title: 'Clear old data',
            subtitle: 'Deletes call history older than the selected period and cleans expired event cache.',
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _selectedDays,
            decoration: const InputDecoration(
              labelText: 'Older than',
              border: OutlineInputBorder(),
            ),
            items: _oldDataDaysOptions
                .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text('$d days'),
                    ))
                .toList(),
            onChanged: _clearingOldData
                ? null
                : (value) {
                    if (value != null) setState(() => _selectedDays = value);
                  },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: _clearingOldData ? null : _clearOldData,
              icon: _clearingOldData
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    )
                  : const Icon(Icons.delete_sweep),
              label: Text(_clearingOldData ? 'Clearing...' : 'Clear old data'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: colorScheme.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
