import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:noscall/call/call_manager.dart';
import 'package:noscall/core/call/contacts/contacts.dart';
import 'package:noscall/utils/toast.dart';

class DataExportPage extends StatefulWidget {
  const DataExportPage({super.key});

  @override
  State<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends State<DataExportPage> {
  bool _exportingCallHistory = false;
  bool _exportingContacts = false;

  Future<String?> _getExportDirectory() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${dir.path}/noscall_export');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      return exportDir.path;
    } catch (e) {
      return null;
    }
  }

  Future<void> _exportCallHistory() async {
    if (_exportingCallHistory) return;
    setState(() => _exportingCallHistory = true);
    try {
      final basePath = await _getExportDirectory();
      if (basePath == null) {
        AppToast.showError(context, 'Failed to get export directory');
        return;
      }
      final manager = CallKitManager.instance.callHistoryManager;
      final groups = manager.callLogGroups;
      final rows = <Map<String, dynamic>>[];
      for (final group in groups) {
        for (final entry in group.callEntries) {
          rows.add({
            'peerPubkey': entry.peerPubkey,
            'direction': entry.direction.value,
            'type': entry.type.name,
            'status': entry.status.value,
            'startTime': entry.startTime.toIso8601String(),
            'durationSeconds': entry.durationSeconds,
          });
        }
      }
      final jsonStr = const JsonEncoder.withIndent('  ').convert(rows);
      final csvLines = <String>[
        'peerPubkey,direction,type,status,startTime,durationSeconds',
        ...rows.map((r) => [
          r['peerPubkey'],
          r['direction'],
          r['type'],
          r['status'],
          r['startTime'],
          r['durationSeconds'],
        ].join(',')),
      ];
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final jsonFile = File('$basePath/call_history_$timestamp.json');
      final csvFile = File('$basePath/call_history_$timestamp.csv');
      await jsonFile.writeAsString(jsonStr);
      await csvFile.writeAsString(csvLines.join('\n'));
      if (mounted) {
        AppToast.showSuccess(context, 'Call history exported');
        _showExportResult(context, 'Call history', [jsonFile.path, csvFile.path]);
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Export failed: $e');
      }
    } finally {
      if (mounted) setState(() => _exportingCallHistory = false);
    }
  }

  Future<void> _exportContacts() async {
    if (_exportingContacts) return;
    setState(() => _exportingContacts = true);
    try {
      final basePath = await _getExportDirectory();
      if (basePath == null) {
        AppToast.showError(context, 'Failed to get export directory');
        return;
      }
      final contacts = Contacts.sharedInstance.allContacts.values.toList();
      final rows = contacts.map((u) => {
        'pubkey': u.pubKey,
        'name': u.name ?? '',
        'nickName': u.nickName ?? '',
        'picture': u.picture ?? '',
      }).toList();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(
        rows.map((r) => r).toList(),
      );
      final csvLines = <String>[
        'pubkey,name,nickName,picture',
        ...rows.map((r) => [
          r['pubkey'] as String,
          r['name'] as String,
          r['nickName'] as String,
          r['picture'] as String,
        ].map((s) => '"${s.replaceAll('"', '""')}"').join(',')),
      ];
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final jsonFile = File('$basePath/contacts_$timestamp.json');
      final csvFile = File('$basePath/contacts_$timestamp.csv');
      await jsonFile.writeAsString(jsonStr);
      await csvFile.writeAsString(csvLines.join('\n'));
      if (mounted) {
        AppToast.showSuccess(context, 'Contacts exported');
        _showExportResult(context, 'Contacts', [jsonFile.path, csvFile.path]);
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Export failed: $e');
      }
    } finally {
      if (mounted) setState(() => _exportingContacts = false);
    }
  }

  void _showExportResult(BuildContext context, String title, List<String> paths) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$title exported'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Files saved to:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ...paths.map((p) => SelectableText(
                p,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontFamily: 'monospace',
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: paths.join('\n')));
              AppToast.showSuccess(ctx, 'Path copied');
            },
            child: const Text('Copy path'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Data export',
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          Text(
            'Export data to JSON and CSV files. Files are saved in the app documents folder.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: Icon(Icons.history, color: colorScheme.primary),
            title: Text(
              'Call history',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              'Export all call records',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: _exportingCallHistory
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: _exportCallHistory,
                  ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.people, color: colorScheme.primary),
            title: Text(
              'Contacts',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              'Export contact list',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: _exportingContacts
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: _exportContacts,
                  ),
          ),
        ],
      ),
    );
  }
}
