import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  late ThemeData theme;
  Color get primary => theme.colorScheme.primary;
  Color get surface => theme.colorScheme.surface;
  Color get onSurface => theme.colorScheme.onSurface;
  Color get onSurfaceVariant => theme.colorScheme.onSurfaceVariant;
  Color get errorColor => theme.colorScheme.error;

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
    theme = Theme.of(context);
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: _buildAppBarTitle(),
      centerTitle: true,
      backgroundColor: surface,
      foregroundColor: onSurface,
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _callBackFromGroup(group),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 16,
              left: 16,
            ),
            child: Row(
              children: [
                _buildUserAvatar(group.peerPubkey, group.type, statusColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContactName(group, statusColor),
                      const SizedBox(height: 4),
                      _buildCallTypeAndDirection(group, statusColor),
                    ],
                  ),
                ),
                _buildRightSideContent(group, statusColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(String peerPubkey, CallType callType, Color statusColor) {
    final user = ChatCore.Account.sharedInstance.getUserNotifier(peerPubkey).value;
    return UserAvatar(
      user: user,
      radius: 24,
    );
  }

  Widget _buildContactName(CallLogGroup group, Color statusColor) {
    final theme = Theme.of(context);
    return ValueListenableBuilder(
      valueListenable: ChatCore.Account.sharedInstance.getUserNotifier(group.peerPubkey),
      builder: (BuildContext context, user, Widget? child) {
        return Text(
          user.displayName(),
          style: theme.textTheme.titleMedium?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }

  Widget _buildCallTypeAndDirection(CallLogGroup group, Color statusColor) {
    final theme = Theme.of(context);

    String directionText = group.direction == CallDirection.incoming ? '↙' : '↗';
    String callTypeText = group.type.isVideo ? 'Video' : 'Audio';
    String fullText = '$directionText $callTypeText';

    if (group.callCount > 1) {
      fullText += ' (${group.callCount})';
    }

    return Text(
      fullText,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: statusColor.withValues(alpha: 0.8),
        fontSize: 14,
      ),
    );
  }

  Widget _buildRightSideContent(CallLogGroup group, Color statusColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          group.formattedLastCallTime,
          style: theme.textTheme.bodySmall?.copyWith(
            color: onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _navigateToUserDetail(group),
          child: Padding(
            padding: const EdgeInsets.only(
              top: 12.0,
              bottom: 12.0,
              left: 12.0,
              right: 16.0,
            ),
            child: Icon(
              CupertinoIcons.info_circle,
              size: 24,
              color: primary,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: errorColor,
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
              color: onSurfaceVariant,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.call_outlined,
            size: 64,
            color: onSurfaceVariant,
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
              color: onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCallStatusColor(CallLogGroup group) {
    return group.isConnected ? primary : errorColor;
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


  Future<void> _callBackFromGroup(CallLogGroup group) async {
    try {
      await CallKitManager.instance.startCall(
        peerId: group.peerPubkey,
        callType: group.type,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start call: $e'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _navigateToUserDetail(CallLogGroup group) {
    context.push(
      '/user-detail',
      extra: {
        'pubkey': group.peerPubkey,
        'callHistory': group.callEntries.reversed.toList(),
      },
    );
  }

  Future<void> _searchCallGroups(String query) async {
    _searchTextController.add(query.trim());
  }
}

extension _CallLogGroupEx on CallLogGroup {
  String get formattedLastCallTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final callDate = DateTime(lastCallTime.year, lastCallTime.month, lastCallTime.day);

    // Today: show time (e.g., "14:04")
    if (callDate == today) {
      return '${lastCallTime.hour.toString().padLeft(2, '0')}:${lastCallTime.minute.toString().padLeft(2, '0')}';
    }

    // Yesterday: show "Yesterday"
    if (callDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }

    // This week: show day of week (Monday, Tuesday, etc.)
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    if (callDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
        callDate.isBefore(weekEnd.add(const Duration(days: 1)))) {
      return _getWeekdayName(lastCallTime.weekday);
    }

    // This year: show month/day (e.g., "12/25")
    if (lastCallTime.year == now.year) {
      return '${lastCallTime.month}/${lastCallTime.day}';
    }

    // Cross year: show year/month/day (e.g., "2023/12/25")
    return '${lastCallTime.year}/${lastCallTime.month}/${lastCallTime.day}';
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[weekday - 1];
  }
}
