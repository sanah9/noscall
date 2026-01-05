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
  final Map<int, TextEditingController> _editingControllers = {};
  final Map<int, FocusNode> _focusNodes = {};
  int _tempIdCounter = -1;

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
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
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

  void _createGroup() {
    final hasNewGroup = _groups.any((g) => g.id < 0);
    if (hasNewGroup) return;
    
    final tempGroup = ContactGroup(
      name: '',
      createTime: DateTime.now().millisecondsSinceEpoch,
      updateTime: DateTime.now().millisecondsSinceEpoch,
    )..id = _tempIdCounter--;
    
    final controller = TextEditingController();
    
    setState(() {
      _groups = [..._groups, tempGroup];
      _editingControllers[tempGroup.id] = controller;
    });
  }

  void _deleteGroup(ContactGroup group) {
    setState(() {
      _groups = _groups.where((g) => g.id != group.id).toList();
      _editingControllers.remove(group.id)?.dispose();
      _focusNodes.remove(group.id)?.dispose();
    });
  }

  void _handleGroupNameFocusLost(int groupId) async {
    final controller = _editingControllers[groupId];
    if (controller == null) return;
    
    final name = controller.text.trim();
    final isNewGroup = groupId < 0;
    
    if (isNewGroup) {
      if (name.isEmpty) {
        setState(() {
          _groups = _groups.where((g) => g.id != groupId).toList();
          _editingControllers.remove(groupId)?.dispose();
          _focusNodes.remove(groupId)?.dispose();
        });
      } else {
        try {
          await _groupService.createGroup(name: name);
          await _loadGroups();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save group: $e')),
            );
            setState(() {
              _groups = _groups.where((g) => g.id != groupId).toList();
              _editingControllers.remove(groupId)?.dispose();
              _focusNodes.remove(groupId)?.dispose();
            });
          }
        }
      }
    }
  }

  Future<void> _saveChanges() async {
    final invalidNewGroups = _groups.where((g) => g.id < 0 && g.name.trim().isEmpty).toList();
    for (final group in invalidNewGroups) {
      setState(() {
        _groups = _groups.where((g) => g.id != group.id).toList();
        _editingControllers.remove(group.id)?.dispose();
      });
    }

    final dbGroups = await _groupService.getAllGroups();
    final dbGroupsMap = {for (var g in dbGroups) g.id: g};
    
    final newGroups = _groups.where((g) => g.id < 0 && g.name.trim().isNotEmpty).toList();
    final dbIds = dbGroupsMap.keys.toSet();
    final memoryIds = _groups.where((g) => g.id > 0).map((g) => g.id).toSet();
    final deletedIds = dbIds.difference(memoryIds);
    
    final updatedGroups = <ContactGroup>[];
    for (final group in _groups) {
      if (group.id > 0) {
        final dbGroup = dbGroupsMap[group.id];
        if (dbGroup != null && dbGroup.name != group.name) {
          updatedGroups.add(group);
        }
      }
    }

    try {
      for (final group in newGroups) {
        await _groupService.createGroup(name: group.name.trim());
      }

      for (final id in deletedIds) {
        await _groupService.deleteGroup(id);
      }

      for (final group in updatedGroups) {
        await _groupService.updateGroupName(group.id, group.name.trim());
      }

      await _loadGroups();
      
      if (mounted) {
        setState(() {
          _isEditing = false;
          for (var controller in _editingControllers.values) {
            controller.dispose();
          }
          for (var focusNode in _focusNodes.values) {
            focusNode.dispose();
          }
          _editingControllers.clear();
          _focusNodes.clear();
        });
      }
    } catch (e) {
      await _loadGroups();
      if (mounted) {
        setState(() {
          _isEditing = false;
          for (var controller in _editingControllers.values) {
            controller.dispose();
          }
          for (var focusNode in _focusNodes.values) {
            focusNode.dispose();
          }
          _editingControllers.clear();
          _focusNodes.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save changes: $e')),
        );
      }
    }
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
                onPressed: _saveChanges,
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
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createGroup,
            tooltip: 'Add Group',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: ListView(
          children: [
            const SizedBox(height: 12),
            _buildAllContactsSection(),
            _buildGroupsSection(),
            const SizedBox(height: 40),
          ],
        ),
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
                    final isLast = index == _groups.length - 1;
                    return _buildGroupItem(group, isLast);
                  }).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildGroupItem(ContactGroup group, bool isLast) {
    final isNewGroup = group.id < 0;
    final controller = _editingControllers[group.id] ?? 
        TextEditingController(text: group.name);
    if (!_editingControllers.containsKey(group.id)) {
      _editingControllers[group.id] = controller;
    }
    
    final focusNode = _focusNodes[group.id] ?? FocusNode();
    if (!_focusNodes.containsKey(group.id)) {
      _focusNodes[group.id] = focusNode;
      if (isNewGroup) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _groups.any((g) => g.id == group.id)) {
            focusNode.requestFocus();
          }
        });
      }
      focusNode.addListener(() {
        if (!focusNode.hasFocus) {
          _handleGroupNameFocusLost(group.id);
        }
      });
    }

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
        future: group.id > 0 ? _getGroupContactCount(group.id) : Future.value(0),
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return ListTile(
            leading: _isEditing && !isNewGroup
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: theme.colorScheme.error,
                    onPressed: () => _deleteGroup(group),
                    tooltip: 'Delete',
                  )
                : null,
            title: _isEditing || isNewGroup
                ? TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: true,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      final index = _groups.indexWhere((g) => g.id == group.id);
                      if (index != -1) {
                        setState(() {
                          _groups[index] = ContactGroup(
                            name: value,
                            createTime: _groups[index].createTime,
                            updateTime: DateTime.now().millisecondsSinceEpoch,
                          )..id = _groups[index].id;
                        });
                      }
                    },
                  )
                : TextField(
                    controller: controller,
                    enabled: false,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      disabledBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                    ),
                  ),
            subtitle: group.id > 0
                ? Text(
                    '$count ${count == 1 ? 'contact' : 'contacts'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onSurfaceVariant,
                    ),
                  )
                : null,
            trailing: _isEditing
                ? null
                : group.id > 0
                    ? Icon(
                        Icons.chevron_right,
                        color: onSurfaceVariant,
                        size: 20,
                      )
                    : null,
            onTap: !_isEditing && group.id > 0
                ? () {
                    context.push(
                      '/group-contacts',
                      extra: {'groupId': group.id, 'groupName': group.name},
                    );
                  }
                : null,
          );
        },
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