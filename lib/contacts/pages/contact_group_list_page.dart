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
    setState(() {
      _groups = groups;
    });
  }

  Future<void> _createGroup() async {
    final group = await _groupService.createGroup();
    await _loadGroups();
    // Automatically enter edit mode for the newly created group
    setState(() {
      _isEditing = true;
      _editingGroupId = group.id;
      _editingControllers[group.id] = TextEditingController(text: group.name);
    });
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
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
      body: Column(
        children: [
          // Pinned section: All Contacts
          _buildAllContactsSection(colorScheme),
          const Divider(height: 1),
          // Custom groups section
          Expanded(
            child: _groups.isEmpty
                ? _buildEmptyState(colorScheme)
                : _buildGroupsList(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildAllContactsSection(ColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Push contacts list page - same API as global router
          context.pushContactsList();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'All Contacts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                '$_allContactsCount',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No custom groups',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the top right to add a group',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList(ColorScheme colorScheme) {
    return ListView.builder(
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        final isEditing = _isEditing && _editingGroupId == group.id;

        return _buildGroupItem(group, isEditing, colorScheme);
      },
    );
  }

  Widget _buildGroupItem(
      ContactGroup group, bool isEditing, ColorScheme colorScheme) {
    if (isEditing && _editingGroupId == group.id) {
      return _buildEditingGroupItem(group, colorScheme);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: FutureBuilder<int>(
                  future: _getGroupContactCount(group.id),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (_isEditing) ...[
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: colorScheme.error,
                  onPressed: () => _deleteGroup(group),
                  tooltip: 'Delete',
                ),
              ] else ...[
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditingGroupItem(
      ContactGroup group, ColorScheme colorScheme) {
    final controller = _editingControllers[group.id];
    if (controller == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface,
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
            color: colorScheme.primary,
            onPressed: () => _saveGroupName(group.id),
            tooltip: 'Save',
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: colorScheme.onSurfaceVariant,
            onPressed: () => _cancelEditing(group.id),
            tooltip: 'Cancel',
          ),
        ],
      ),
    );
  }
}