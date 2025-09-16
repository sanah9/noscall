import 'package:flutter/material.dart';

class RecentCallsPage extends StatefulWidget {
  const RecentCallsPage({super.key});

  @override
  State<RecentCallsPage> createState() => _RecentCallsPageState();
}

class _RecentCallsPageState extends State<RecentCallsPage> {
  final List<Map<String, dynamic>> _recentCalls = [
    {
      'name': 'Alice Johnson',
      'pubkey': 'npub1alice...',
      'type': 'outgoing',
      'callType': 'audio',
      'duration': '2:34',
      'time': '2024-01-15 14:30',
      'status': 'completed',
    },
    {
      'name': 'Bob Smith',
      'pubkey': 'npub1bob...',
      'type': 'incoming',
      'callType': 'video',
      'duration': '0:45',
      'time': '2024-01-14 09:15',
      'status': 'missed',
    },
    {
      'name': 'Charlie Brown',
      'pubkey': 'npub1charlie...',
      'type': 'outgoing',
      'callType': 'audio',
      'duration': '1:23',
      'time': '2024-01-13 16:45',
      'status': 'completed',
    },
    {
      'name': 'Unknown Caller',
      'pubkey': 'npub1unknown...',
      'type': 'incoming',
      'callType': 'audio',
      'duration': '0:00',
      'time': '2024-01-12 11:20',
      'status': 'missed',
    },
  ];

  IconData _getCallTypeIcon(String callType) {
    return callType == 'video' ? Icons.videocam : Icons.call;
  }

  Color _getCallStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'completed':
        return colorScheme.primary;
      case 'missed':
        return colorScheme.error;
      case 'declined':
        return colorScheme.tertiary;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Calls'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement clear call history functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Clear call history feature coming soon'),
                  backgroundColor: colorScheme.inverseSurface,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _recentCalls.length,
        itemBuilder: (context, index) {
          final call = _recentCalls[index];
          final statusColor = _getCallStatusColor(call['status'], colorScheme);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            elevation: 1,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: statusColor,
                child: Icon(
                  _getCallTypeIcon(call['callType']),
                  color: colorScheme.onPrimary,
                  size: 20,
                ),
              ),
              title: Text(
                call['name'],
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: call['status'] == 'missed' ? FontWeight.bold : FontWeight.w500,
                  color: call['status'] == 'missed' ? colorScheme.error : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    call['pubkey'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    call['time'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    call['duration'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Icon(
                    call['type'] == 'incoming' ? Icons.call_received : Icons.call_made,
                    size: 16,
                    color: statusColor,
                  ),
                ],
              ),
              onTap: () {
                // TODO: Implement callback functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Calling back ${call['name']}...'),
                    backgroundColor: colorScheme.inverseSurface,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              onLongPress: () {
                // TODO: Show call details dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Call Details'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Name: ${call['name']}'),
                        Text('Type: ${call['type']}'),
                        Text('Call Type: ${call['callType']}'),
                        Text('Duration: ${call['duration']}'),
                        Text('Time: ${call['time']}'),
                        Text('Status: ${call['status']}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
