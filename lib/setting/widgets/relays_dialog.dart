import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:noscall/component/icon.dart';
import '../../core/account/relays.dart';
import '../../core/common/network/connect.dart';
import '../../utils/modal_dialog.dart';

class RelaysDialog extends StatefulWidget {
  const RelaysDialog({super.key});

  static void show(BuildContext context) {
    AppModalDialog.showDialog(
      context: context,
      child: const RelaysDialog(),
    );
  }

  @override
  State<RelaysDialog> createState() => _RelaysDialogState();
}

class _RelaysDialogState extends State<RelaysDialog> {
  late ThemeData theme;
  Color get primary => theme.colorScheme.primary;
  Color get surface => theme.colorScheme.surface;
  Color get onSurface => theme.colorScheme.onSurface;
  Color get onSurfaceVariant => theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
  Color get primaryContainer => theme.colorScheme.primaryContainer.withValues(alpha: 0.3);
  Color get onPrimaryContainer => theme.colorScheme.onPrimaryContainer;
  Color get borderColor => theme.colorScheme.outline.withValues(alpha: 0.1);

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final relays = Relays.sharedInstance.recommendGeneralRelays;
    final connect = Connect.sharedInstance;

    int connectedCount = 0;
    for (final relay in relays) {
      final socket = connect.webSockets[relay];
      if (socket?.connectStatus == 1) {
        connectedCount++;
      }
    }

    final isActive = connectedCount > 0;
    final statusText = connectedCount == 0
        ? 'All relays disconnected'
        : '$connectedCount of ${relays.length} relays connected';

    return Container(
      color: surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, primaryColor, statusText, isActive),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: relays.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildRelayItem(context, relays[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Color primaryColor,
    String statusText,
    bool isActive,
  ) {
    return Container(
      color: primaryColor,
      padding: const EdgeInsets.only(
        left: 20,
        right: 6,
        top: 12,
        bottom: 12,
      ),
      child: Row(
        children: [
          SSIcon(
            icon: Icons.dns,
            size: 36,
            color: primaryColor,
            isWhiteStyle: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'App Relays',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isActive 
                  ? Colors.green
                  : Colors.red,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              isActive ? 'Active' : 'Inactive',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 24),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildRelayItem(BuildContext context, String relay) {
    final connect = Connect.sharedInstance;
    final socket = connect.webSockets[relay];
    final status = socket?.connectStatus ?? 3;

    final isConnected = status == 1;
    final isWarning = status != 0 && status != 1;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          _buildStatusIndicator(isConnected, isWarning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  relay,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusText(status),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(bool isConnected, bool isWarning) {
    if (isConnected) {
      return const Icon(
        CupertinoIcons.check_mark_circled,
        color: Colors.green,
        size: 20,
      );
    } else if (isWarning) {
      return Icon(
        Icons.warning_amber_rounded,
        color: Colors.orange.shade700,
        size: 20,
      );
    } else {
      return Icon(
        Icons.circle_outlined,
        color: onSurfaceVariant,
        size: 20,
      );
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return 'Connecting...';
      case 1:
        return 'Connected';
      case 2:
        return 'Closing...';
      case 3:
      default:
        return 'Disconnected';
    }
  }
}

