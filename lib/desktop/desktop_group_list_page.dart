import 'package:flutter/material.dart';
import '../contacts/models/contact_group_isar.dart';
import '../contacts/services/contact_group_service.dart';
import '../core/call/contacts/contacts.dart';
import 'desktop_contacts_page.dart';
import 'desktop_page_wrapper.dart';
import '../contacts/pages/group_contacts_page.dart';

class DesktopGroupListPage extends StatefulWidget {
  const DesktopGroupListPage({super.key});

  @override
  State<DesktopGroupListPage> createState() => _DesktopGroupListPageState();
}

class _DesktopGroupListPageState extends State<DesktopGroupListPage> {
  final ContactGroupService _groupService = ContactGroupService.sharedInstance;
  List<ContactGroup> _groups = [];
  final Map<int, int> _groupCountCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final groups = await _groupService.getAllGroups();
    if (mounted) {
      setState(() {
        _groups = groups;
        _groupCountCache.clear();
        _isLoading = false;
      });
    }
  }

  Future<int> _getGroupContactCount(int groupId) async {
    return _groupService.getGroupContactCount(groupId);
  }

  void _openAllContacts() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DesktopContactsPage(),
      ),
    );
  }

  void _openGroup(ContactGroup group) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroupContactsPage(
          groupId: group.id,
          groupName: group.name,
        ),
      ),
    ).then((_) {
      // Refresh count when returning from group detail
      if (mounted) _loadGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final allContactsCount = Contacts.sharedInstance.allContacts.length;

    return DesktopPageWrapper(
      title: 'Groups',
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _ListTileItem(
                  leading: Icon(
                    Icons.people_outline,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  title: 'All Contacts',
                  subtitle: '$allContactsCount contacts',
                  onTap: _openAllContacts,
                ),
                if (_groups.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Text(
                      'Custom Groups',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  ..._groups.map(
                    (group) => FutureBuilder<int>(
                      future: _getGroupContactCount(group.id),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? _groupCountCache[group.id] ?? 0;
                        if (snapshot.hasData && mounted) {
                          _groupCountCache[group.id] = count;
                        }
                        return _ListTileItem(
                          leading: Icon(
                            Icons.folder_outlined,
                            color: colorScheme.primary.withValues(alpha: 0.8),
                            size: 24,
                          ),
                          title: group.name,
                          subtitle: '$count ${count == 1 ? 'contact' : 'contacts'}',
                          onTap: () => _openGroup(group),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _ListTileItem extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ListTileItem({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
