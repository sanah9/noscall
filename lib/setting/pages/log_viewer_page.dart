import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/core/common/utils/log_utils.dart';
import 'package:noscall/core/navigation/app_navigator_scope.dart';
import 'package:noscall/utils/toast.dart';

class LogViewerPage extends StatelessWidget {
  const LogViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Logs',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy logs',
            onPressed: () {
              final text = LogUtils.logLines.join('\n');
              if (text.isEmpty) {
                AppToast.showInfo(context, 'No logs to copy');
                return;
              }
              Clipboard.setData(ClipboardData(text: text));
              AppToast.showSuccess(context, 'Logs copied to clipboard');
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<String>>(
        valueListenable: LogUtils.logLinesNotifier,
        builder: (context, lines, _) {
          if (lines.isEmpty) {
            return Center(
              child: Text(
                'No logs yet. Logs appear here when the app runs.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: lines.length,
            itemBuilder: (context, index) {
              final line = lines[index];
              return SelectableText(
                line,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
