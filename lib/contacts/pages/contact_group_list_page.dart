import 'package:flutter/material.dart';
import '../models/contact_group_isar.dart';
import '../services/contact_group_service.dart';
import '../../core/call/contacts/contacts.dart';
import '../../core/common/database/db_isar.dart';
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
  final Map<int, int> _groupCountCache = {};
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
        _groupCountCache.clear();
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
          final saved = await _groupService.createGroup(name: name);
          if (!mounted) return;
          final idx = _groups.indexWhere((g) => g.id == groupId);
          if (idx >= 0) {
            final oldId = groupId;
            final newId = saved.id;
            _groups = [..._groups]..[idx] = saved;
            _editingControllers[newId] = _editingControllers.remove(oldId)!;
            final fn = _focusNodes.remove(oldId);
            if (fn != null) _focusNodes[newId] = fn;
            _groupCountCache[newId] = 0;
          }
          setState(() {});
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
      return;
    }

    // Existing group (id > 0): persist rename
    final idx = _groups.indexWhere((g) => g.id == groupId);
    if (idx < 0 || name.isEmpty || name == _groups[idx].name) return;
    try {
      await _groupService.updateGroupName(groupId, name);
      if (!mounted) return;
      _groups[idx].name = name;
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to rename group: $e')),
        );
      }
    }
  }

  void preCheckGroupsData() {
    bool isChanged = false;
    _groups.removeWhere((g) {
      final isInvalid = g.name.trim().isEmpty;
      if (isInvalid) isChanged = true;
      return isInvalid;
    });
    if (isChanged) {
      setState(() {});
    }
  }

  Future<void> _syncToDatabase() async {
    final validGroups = _groups.where((g) => g.name.trim().isNotEmpty).toList();
    
    for (final group in validGroups) {
      group.name = group.name.trim();
    }
    
    await DBISAR.sharedInstance.saveObjectsToDB(validGroups);
    await Future.delayed(const Duration(milliseconds: 250));
    
    final dbGroups = await _groupService.getAllGroups();
    final validGroupIds = validGroups.where((g) => g.id > 0).map((g) => g.id).toSet();
    
    for (final dbGroup in dbGroups) {
      if (!validGroupIds.contains(dbGroup.id)) {
        await _groupService.deleteGroup(dbGroup.id);
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
        leadingWidth: 70,
        leading: _isEditing
            ? IconButton(
                padding: const EdgeInsets.only(left: 16),
                icon: const Text('Done', style: TextStyle(fontSize: 16)),
                onPressed: () async {
                  try {
                    // Sync editing controller text back to group.name before save
                    for (final g in _groups) {
                      final c = _editingControllers[g.id];
                      if (c != null) g.name = c.text.trim();
                    }
                    preCheckGroupsData();
                    await _syncToDatabase();
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
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to sync to database: $e')),
                      );
                    }
                  }
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
          IconButton(
            padding: const EdgeInsets.only(right: 20),
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
                  ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: (_, index) {
                      final group = _groups[index];
                      return _buildGroupItem(group);
                    },
                    separatorBuilder: (_, __) => Container(
                      color: borderColor,
                      height: 0.5,
                    ),
                    itemCount: _groups.length,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGroupItem(ContactGroup group) {
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

    return FutureBuilder<int>(
      future: group.id > 0 
          ? (_groupCountCache.containsKey(group.id) 
              ? Future.value(_groupCountCache[group.id]!) 
              : _getGroupContactCount(group.id).then((count) {
                  if (mounted) {
                    _groupCountCache[group.id] = count;
                  }
                  return count;
                }))
          : Future.value(0),
      builder: (context, snapshot) {
        final count = snapshot.data ?? _groupCountCache[group.id] ?? 0;
        return ListTile(
          leading: _isEditing
              ? IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: theme.colorScheme.error,
                  onPressed: () => _deleteGroup(group),
                  tooltip: 'Delete',
                )
              : null,
          title: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: _isEditing || isNewGroup,
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
          subtitle: Text(
            '$count ${count == 1 ? 'contact' : 'contacts'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: onSurfaceVariant,
            ),
          ),
          trailing: _isEditing
              ? null
              : Icon(
                Icons.chevron_right,
                color: onSurfaceVariant,
                size: 20,
              ),
          onTap: _isEditing
              ? null
              : () async {
                final result = await context.pushGroupContacts(group.id, group.name);
                if (result != null && mounted) {
                  setState(() {
                    _groupCountCache[group.id] = result;
                  });
                }
              },
        );
      },
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