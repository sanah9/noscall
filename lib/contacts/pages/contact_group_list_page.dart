import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/contact_group_isar.dart';
import '../services/contact_group_service.dart';
import '../../core/call/contacts/contacts.dart';
import '../contact_navigation_extension.dart';

class ContactGroupListPage extends StatefulWidget {
  const ContactGroupListPage({super.key});

  @override
  State<ContactGroupListPage> createState() => _ContactGroupListPageState();
}

class _ContactGroupListPageState extends State<ContactGroupListPage> {
  final ContactGroupService _groupService = ContactGroupService.sharedInstance;
  List<ContactGroup> _groups = [];
  bool _isEditing = false;
  int? _editingGroupId;
  final Map<int, TextEditingController> _editingControllers = {};

  late ThemeData theme;
  BorderRadius get sectionRadius => BorderRadius.circular(16);
  Color get primary => theme.colorScheme.primary;
  Color get primaryContainer => theme.colorScheme.primaryContainer.withValues(alpha: 0.3);
  Color get surface => theme.colorScheme.surface;
  Color get onSurface => theme.colorScheme.onSurface;
  Color get onSurfaceVariant => theme.colorScheme.onSurfaceVariant;
  Color get borderColor => theme.colorScheme.outline.withValues(alpha: 0.1);

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    for (var controller in _editingControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadGroups() async {
    final groups = await _groupService.getAllGroups();
    if (mounted) {
      setState(() {
        _groups = groups;
      });
    }
  }

  Future<void> _createGroup() async {
    await _groupService.createGroup();
    await _loadGroups();
  }

  Future<void> _deleteGroup(ContactGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text('Are you sure you want to delete group "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _groupService.deleteGroup(group.id);
      await _loadGroups();
    }
  }

  Future<void> _saveGroupName(int groupId) async {
    final controller = _editingControllers[groupId];
    if (controller != null) {
      final newName = controller.text.trim();
      if (newName.isNotEmpty) {
        await _groupService.updateGroupName(groupId, newName);
        await _loadGroups();
      }
    }
    setState(() {
      _editingGroupId = null;
      _editingControllers.remove(groupId)?.dispose();
    });
  }

  void _startEditing(int groupId, String currentName) {
    setState(() {
      _editingGroupId = groupId;
      _editingControllers[groupId] = TextEditingController(text: currentName);
    });
  }

  void _cancelEditing(int groupId) {
    setState(() {
      _editingGroupId = null;
      _editingControllers.remove(groupId)?.dispose();
    });
  }

  Future<int> _getGroupContactCount(int groupId) async {
    return await _groupService.getGroupContactCount(groupId);
  }

  int get _allContactsCount => Contacts.sharedInstance.allContacts.length;

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        centerTitle: true,
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        leading: _isEditing
            ? IconButton(
                icon: const Text('Done', style: TextStyle(fontSize: 16)),
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _editingGroupId = null;
                    for (var controller in _editingControllers.values) {
                      controller.dispose();
                    }
                    _editingControllers.clear();
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                tooltip: 'Edit',
              ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _createGroup,
              tooltip: 'Add Group',
            ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          // Pinned section: All Contacts
          _buildAllContactsSection(),
          // Custom groups section
          _buildGroupsSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAllContactsSection() {
    return _buildSectionContainer(
      child: ListTile(
        title: Text(
          'All Contacts',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '$_allContactsCount contacts',
          style: theme.textTheme.bodySmall?.copyWith(
            color: onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: onSurfaceVariant,
          size: 20,
        ),
        onTap: () {
          context.pushContactsList();
        },
      ),
    );
  }

  Widget _buildGroupsSection() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _groups.isEmpty
          ? const SizedBox.shrink()
          : _buildSectionContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                    ),
                    child: Text(
                      'Custom Groups',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ..._groups.asMap().entries.map((entry) {
                    final index = entry.key;
                    final group = entry.value;
                    final isEditing = _isEditing && _editingGroupId == group.id;
                    final isLast = index == _groups.length - 1;

                    if (isEditing && _editingGroupId == group.id) {
                      return _buildEditingGroupItem(group, isLast);
                    }
                    return _buildGroupItem(group, isEditing, isLast);
                  }).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildGroupItem(ContactGroup group, bool isEditing, bool isLast) {
    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(
            color: borderColor,
            width: 0.5,
          ),
        ),
      ),
      child: FutureBuilder<int>(
        future: _getGroupContactCount(group.id),
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return ListTile(
            title: Text(
              group.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              '$count ${count == 1 ? 'contact' : 'contacts'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: onSurfaceVariant,
              ),
            ),
            trailing: _isEditing
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: theme.colorScheme.error,
                    onPressed: () => _deleteGroup(group),
                    tooltip: 'Delete',
                  )
                : Icon(
                    Icons.chevron_right,
                    color: onSurfaceVariant,
                    size: 20,
                  ),
            onTap: _isEditing
                ? () {
                    _startEditing(group.id, group.name);
                  }
                : () {
                    context.push(
                      '/group-contacts',
                      extra: {'groupId': group.id, 'groupName': group.name},
                    );
                  },
          );
        },
      ),
    );
  }

  Widget _buildEditingGroupItem(ContactGroup group, bool isLast) {
    final controller = _editingControllers[group.id];
    if (controller == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(
            color: borderColor,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(
                  fontSize: 16,
                  color: onSurface,
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onSubmitted: (_) => _saveGroupName(group.id),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.check),
              color: primary,
              onPressed: () => _saveGroupName(group.id),
              tooltip: 'Save',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              color: onSurfaceVariant,
              onPressed: () => _cancelEditing(group.id),
              tooltip: 'Cancel',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: _buildBlurBackgroundDecoration(),
      child: ClipRRect(
        borderRadius: sectionRadius,
        child: Material(
          color: Colors.transparent,
          child: child,
        ),
      ),
    );
  }

  BoxDecoration _buildBlurBackgroundDecoration() {
    return BoxDecoration(
      color: primaryContainer,
      borderRadius: sectionRadius,
      border: Border.all(
        color: borderColor,
        width: 0.5,
      ),
    );
  }
}