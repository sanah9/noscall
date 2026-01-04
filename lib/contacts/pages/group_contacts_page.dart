import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import 'package:noscall/core/account/account.dart' as ChatCore;
import '../../core/call/contacts/contacts.dart';
import '../services/contact_group_service.dart';
import '../user_avatar.dart';

class GroupContactsPage extends StatefulWidget {
  final int groupId;
  final String groupName;

  const GroupContactsPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupContactsPage> createState() => _GroupContactsPageState();
}

class _GroupContactsPageState extends State<GroupContactsPage> {
  final ContactGroupService _groupService = ContactGroupService.sharedInstance;
  List<String> _contactPubKeys = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });
    final pubKeys = await _groupService.getGroupContactPubKeys(widget.groupId);
    setState(() {
      _contactPubKeys = pubKeys;
      _isLoading = false;
    });
  }

  Future<void> _addContacts() async {
    final selectedContacts = await context.push<List<String>>(
      '/contact-select',
      extra: {'excludePubKeys': _contactPubKeys},
    );

    if (selectedContacts != null && selectedContacts.isNotEmpty) {
      await _groupService.addContactsToGroup(widget.groupId, selectedContacts);
      await _loadContacts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _addContacts,
            tooltip: 'Add Contact',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contactPubKeys.isEmpty
              ? _buildEmptyState(colorScheme)
              : _buildContactsList(colorScheme),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No contacts in this group',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the top right to add contacts',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList(ColorScheme colorScheme) {
    final contacts = _contactPubKeys
        .map((pubKey) => Contacts.sharedInstance.allContacts[pubKey])
        .whereType<UserDBISAR>()
        .toList();

    if (contacts.isEmpty) {
      return _buildEmptyState(colorScheme);
    }

    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return _buildContactCard(context, contact, colorScheme);
      },
    );
  }

  Widget _buildContactCard(
      BuildContext context, UserDBISAR contact, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<UserDBISAR>(
      valueListenable: ChatCore.Account.sharedInstance.getUserNotifier(contact.pubKey),
      builder: (context, updatedUser, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.push(
                '/user-detail',
                extra: {'pubkey': contact.pubKey},
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  UserAvatar(
                    user: updatedUser,
                    size: 48,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          updatedUser.displayName(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          updatedUser.shortEncodedPubkey,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

