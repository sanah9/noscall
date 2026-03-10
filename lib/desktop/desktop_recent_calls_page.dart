import 'dart:async';
import 'package:flutter/material.dart';
import 'package:noscall/call/call_kit_manager.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/call_history/controller/call_history_manager.dart';
import 'package:noscall/call_history/constants/call_enums.dart';
import 'package:noscall/contacts/user_avatar.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/call_history/models/call_log_group.dart';
import 'package:noscall/component/empty_search_state.dart';
import 'package:noscall/core/navigation/app_navigator_scope.dart';
import 'package:noscall/utils/search_field_mixin.dart';
import 'desktop_page_wrapper.dart';

class DesktopRecentCallsPage extends StatefulWidget {
  const DesktopRecentCallsPage({super.key});

  @override
  State<DesktopRecentCallsPage> createState() => _DesktopRecentCallsPageState();
}

class _DesktopRecentCallsPageState extends State<DesktopRecentCallsPage>
    with SearchFieldMixin<DesktopRecentCallsPage> {
  late final CallHistoryManager _manager = CallKitManager.instance.callHistoryManager;
  final StreamController<String> _searchTextController = StreamController<String>.broadcast();

  @override
  void initState() {
    super.initState();
    initSearchField(
      onSearchQueryChanged: (q) => _searchTextController.add(q),
    );
    _manager.initialize();
    _manager.loadUnreadMissedCount();
    _manager.persistUnreadCleared();
  }

  @override
  void dispose() {
    _manager.dispose();
    disposeSearchField();
    _searchTextController.close();
    super.dispose();
  }

  List<CallLogGroup> _filterCallGroups(List<CallLogGroup> groups, String query) {
    if (query.isEmpty) return groups;

    final lowerQuery = query.toLowerCase();
    return groups.where((group) {
      final contact = Account.sharedInstance.getUserNotifier(group.peerPubkey).value;
      final name = (contact.name ?? '').toLowerCase();
      final displayName = contact.displayName().toLowerCase();
      return name.contains(lowerQuery) || displayName.contains(lowerQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DesktopPageWrapper(
      title: 'Recent Calls',
      trailing: DesktopSearchBar(
        controller: searchController,
        hintText: 'Search...',
      ),
      child: StreamBuilder<List<CallLogGroup>>(
        stream: _manager.dataChangeStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.call_outlined,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recent calls',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return StreamBuilder<String>(
            stream: _searchTextController.stream,
            initialData: '',
            builder: (context, searchSnapshot) {
              final searchQuery = searchSnapshot.data ?? '';
              final filteredGroups = _filterCallGroups(snapshot.data!, searchQuery);

              if (filteredGroups.isEmpty) {
                return const Center(
                  child: EmptySearchState(),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filteredGroups.length,
                itemBuilder: (context, index) {
                  final group = filteredGroups[index];
                  return _CallLogGroupItem(
                    group: group,
                    onTap: () {
                      AppNavigatorScope.requireOf(context).pushUserDetail(
                        context,
                        group.peerPubkey,
                        callHistory: group.callEntries.reversed.toList(),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _CallLogGroupItem extends StatelessWidget {
  final CallLogGroup group;
  final VoidCallback onTap;

  const _CallLogGroupItem({
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final contact = Account.sharedInstance.getUserNotifier(group.peerPubkey).value;
    final displayName = contact.displayName();

    final isIncoming = group.direction == CallDirection.incoming;
    final isMissed = !group.isConnected;

    IconData callIcon = isIncoming
        ? Icons.phone_callback
        : Icons.phone_forwarded;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              _buildAvatar(group.peerPubkey),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isMissed ? colorScheme.error : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          callIcon,
                          size: 16,
                          color: isMissed ? colorScheme.error : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          group.type == CallType.video ? 'Video' : 'Audio',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isMissed ? colorScheme.error : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (group.callCount > 1) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${group.callCount})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isMissed ? colorScheme.error : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (isMissed) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Missed',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                _formatTimestamp(group.lastCallTime),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.info_outline,
                size: 20,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String peerId) {
    final contact = Account.sharedInstance.getUserNotifier(peerId).value;
    return UserAvatar(
      user: contact,
      size: 48,
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }
}