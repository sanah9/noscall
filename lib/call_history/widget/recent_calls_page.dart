import 'dart:async';

import 'package:flutter/material.dart';
import 'package:noscall/call/call_manager.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/call_history/controller/call_history_manager.dart';
import 'package:noscall/call_history/constants/call_enums.dart';
import 'package:noscall/contacts/user_avatar.dart';
import 'package:noscall/core/account/account.dart' as ChatCore;

import '../models/call_log_group.dart';

class RecentCallsPage extends StatefulWidget {
  const RecentCallsPage({super.key});

  @override
  State<RecentCallsPage> createState() => _RecentCallsPageState();
}

class _RecentCallsPageState extends State<RecentCallsPage> {
  final CallHistoryManager _manager = CallHistoryManager();

  final TextEditingController _searchController = TextEditingController();

  final StreamController<bool> _showSearchController = StreamController<bool>.broadcast();
  Stream<bool> get _showSearchStream => _showSearchController.stream;

  final StreamController<String> _searchTextController = StreamController<String>.broadcast();
  Stream<String> get _searchTextStream => _searchTextController.stream;

  @override
  void initState() {
    super.initState();
    CallKitManager.instance.callHistoryManager = _manager;
    _manager.initialize();
  }

  @override
  void dispose() {
    CallKitManager.instance.callHistoryManager = null;
    _manager.dispose();
    _searchController.dispose();
    _showSearchController.close();
    _searchTextController.close();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      title: _buildAppBarTitle(),
      centerTitle: true,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      actions: [_buildAppBarActions()],
    );
  }

  Widget _buildAppBarTitle() {
    return StreamBuilder<bool>(
      stream: _showSearchStream,
      initialData: false,
      builder: (context, snapshot) {
        final showSearch = snapshot.data ?? false;
        if (showSearch) {
          return TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search calls...',
              border: InputBorder.none,
            ),
            onChanged: _searchCallGroups,
            autofocus: true,
          );
        }
        return const Text('Recent Calls');
      },
    );
  }

  Widget _buildAppBarActions() {
    return StreamBuilder<bool>(
      stream: _showSearchStream,
      initialData: false,
      builder: (context, snapshot) {
        final showSearch = snapshot.data ?? false;
        if (!showSearch) {
          return Row(
            children: [
              IconButton(
                onPressed: _toggleSearch,
                icon: const Icon(Icons.search),
                tooltip: 'Search',
              ),
              _buildMenuButton(),
            ],
          );
        } else {
          return IconButton(
            onPressed: _closeSearch,
            icon: const Icon(Icons.close),
            tooltip: 'Close Search',
          );
        }
      },
    );
  }

  Widget _buildMenuButton() {
    return PopupMenuButton<String>(
      onSelected: _handleMenuAction,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'clear',
          child: Row(
            children: [
              Icon(Icons.clear_all),
              SizedBox(width: 8),
              Text('Clear History'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return StreamBuilder<List<CallLogGroup>>(
      stream: _manager.dataChangeStream,
      initialData: _manager.callLogGroups,
      builder: (BuildContext context, AsyncSnapshot<List<CallLogGroup>> snapshot) {
        switch ((snapshot.connectionState, snapshot.data)) {
          case (ConnectionState.waiting, _):
            return _buildLoadingState();
          case (_, final List<CallLogGroup> data):
            if (data.isEmpty) return _buildEmptyState();
            return _buildCallGroupList(data);
          default:
            final errorText = snapshot.error?.toString() ?? '';
            if (errorText.isNotEmpty) {
              return _buildErrorState(errorText);
            } else {
              return _buildEmptyState();
            }
        }
      },
    );
  }

  Widget _buildUserAvatar(String peerPubkey, CallType callType, Color statusColor) {
    final user = ChatCore.Account.sharedInstance.getUserNotifier(peerPubkey).value;
    return Stack(
      children: [
        UserAvatar(
          user: user,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 2,
              ),
            ),
            child: Icon(
              _getCallTypeIcon(callType),
              size: 8,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading calls',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _manager.initialize(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.call_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No recent calls',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Your call history will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallGroupList(List<CallLogGroup> callGroups) {
    return ListView.builder(
      itemCount: callGroups.length,
      itemBuilder: (context, index) => _buildCallGroupItem(
        context,
        callGroups[index],
      ),
    );
  }

  Widget _buildCallGroupItem(BuildContext context, CallLogGroup group) {
    final statusColor = _getCallStatusColor(group);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      child: ListTile(
        leading: _buildUserAvatar(group.peerPubkey, group.type, statusColor),
        title: _buildCallGroupTitle(group),
        subtitle: _buildCallGroupSubtitle(group),
        trailing: _buildCallGroupTrailing(group, statusColor),
        onTap: () => _callBackFromGroup(group),
        onLongPress: () => _showCallGroupDetailsDialog(group),
      ),
    );
  }


  Widget _buildCallGroupTitle(CallLogGroup group) {
    final theme = Theme.of(context);
    final color = _getCallStatusColor(group);
    return ValueListenableBuilder(
      valueListenable: ChatCore.Account.sharedInstance.getUserNotifier(group.peerPubkey),
      builder: (BuildContext context, user, Widget? child) {
        final userName = user.displayName();
        final count = group.callCount > 1 ? '(${group.callCount})' : '';
        return Text(
          '$userName$count',
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
          ),
        );
      },
    );
  }

  Widget _buildCallGroupSubtitle(CallLogGroup group) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Text(
      _formatNpub(group.peerPubkey),
      style: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildCallGroupTrailing(CallLogGroup group, Color statusColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 8),
        _buildTimeAndDirectionColumn(group, statusColor),
      ],
    );
  }

  Widget _buildTimeAndDirectionColumn(CallLogGroup group, Color statusColor) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          group.formattedLastCallTime,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Icon(
          group.direction == CallDirection.incoming
              ? Icons.call_received
              : Icons.call_made,
          size: 16,
          color: statusColor,
        ),
      ],
    );
  }

  Color _getCallStatusColor(CallLogGroup group) {
    final colorScheme = Theme.of(context).colorScheme;
    return group.isConnected ? colorScheme.primary : colorScheme.error;
  }

  String _formatNpub(String pubkey) {
    if (pubkey.length > 12) {
      return 'npub1${pubkey.substring(0, 6)}...${pubkey.substring(pubkey.length - 6)}';
    }
    return pubkey;
  }

  void _toggleSearch() {
    _showSearchController.add(true);
  }

  void _closeSearch() {
    _showSearchController.add(false);
    _searchController.clear();
    _searchTextController.add('');
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'clear':
        _clearAllCalls();
        break;
    }
  }

  Future<void> _clearAllCalls() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Call History'),
        content: const Text('Are you sure you want to clear all call history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _manager.deleteAllHistory();
    }
  }

  Future<void> _deleteCallGroup(CallLogGroup group) async {
    await _manager.deleteCallLogGroup(group.groupId);
  }

  Future<void> _callBackFromGroup(CallLogGroup group) async {
    try {
      await CallKitManager().startCall(
        peerId: group.peerPubkey,
        callType: group.type,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start call: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _searchCallGroups(String query) async {
    _searchTextController.add(query.trim());
  }

  IconData _getCallTypeIcon(CallType callType) {
    return callType.isVideo ? Icons.videocam : Icons.call;
  }

  void _showCallGroupDetailsDialog(CallLogGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Call Group Details (${group.callCount} calls)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${group.displayName}'),
              Text('Pubkey: ${group.peerPubkey}'),
              Text('Direction: ${group.direction.value}'),
              Text('Type: ${group.type.value}'),
              Text('Connected: ${group.isConnected ? "Yes" : "No"}'),
              Text('First Call: ${group.firstCallTime.toString()}'),
              Text('Last Call: ${group.lastCallTime.toString()}'),
              Text('Call Count: ${group.callCount}'),
              const SizedBox(height: 16),
              const Text('Note: Individual call details are stored separately'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _callBackFromGroup(group);
            },
            child: const Text('Call Back'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteCallGroup(group);
            },
            child: const Text('Delete Group'),
          ),
        ],
      ),
    );
  }
}

extension asd on CallLogGroup {
  String get displayName => _shortPubkey;

  String get _shortPubkey => peerPubkey.length > 12
      ? '${peerPubkey.substring(0, 6)}...${peerPubkey.substring(peerPubkey.length - 6)}'
      : peerPubkey;

  String get formattedLastCallTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final callDate = DateTime(lastCallTime.year, lastCallTime.month, lastCallTime.day);

    if (callDate == today) {
      return '${lastCallTime.hour.toString().padLeft(2, '0')}:${lastCallTime.minute.toString().padLeft(2, '0')}';
    } else if (callDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${lastCallTime.day}/${lastCallTime.month}/${lastCallTime.year}';
    }
  }

  DateTime get firstCallTime => lastCallTime;
}
