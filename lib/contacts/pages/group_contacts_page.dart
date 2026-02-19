import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import 'package:noscall/core/call/contacts/contacts.dart';
import 'package:noscall/contacts/services/contact_group_service.dart';
import 'package:noscall/contacts/services/contact_navigation_service.dart';
import 'package:noscall/contacts/contact_navigation_extension.dart';
import 'package:noscall/component/contact_list_tile.dart';
import 'package:noscall/component/empty_search_state.dart';

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
  final TextEditingController _searchController = TextEditingController();
  List<String> _contactPubKeys = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Save group ID when this page is opened
    ContactNavigationService.sharedInstance.saveLastGroupId(widget.groupId);
    
    _loadContacts();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _removeContact(String pubKey, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Contact'),
        content: Text('Remove "$displayName" from this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _groupService.removeContactsFromGroup(widget.groupId, [pubKey]);
      await _loadContacts();
    }
  }

  List<UserDBISAR> _filterContacts(List<UserDBISAR> contacts) {
    if (_searchQuery.isEmpty) return contacts;

    final query = _searchQuery.toLowerCase();
    return contacts.where((contact) {
      final name = (contact.name ?? '').toLowerCase();
      final nickName = (contact.nickName ?? '').toLowerCase();
      
      return name.contains(query) || nickName.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final contacts = _contactPubKeys
        .map((pubKey) => Contacts.sharedInstance.allContacts[pubKey])
        .whereType<UserDBISAR>()
        .toList();
    final filteredContacts = _filterContacts(contacts);
    final hasContacts = contacts.isNotEmpty;
    final hasSearchResults = filteredContacts.isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          context.popContactPage(_contactPubKeys.length);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.groupName),
          centerTitle: true,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () {
              context.popContactPage(_contactPubKeys.length);
            },
          ),
          actions: [
            IconButton(
              padding: const EdgeInsets.only(right: 12),
              icon: const Icon(Icons.person_add),
              onPressed: _addContacts,
              tooltip: 'Add Contact',
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Column(
            children: [
              if (!_isLoading) _buildSearchBar(colorScheme),
              Expanded(
                child: _isLoading
            ? const Center(child: CircularProgressIndicator())
                    : !hasContacts
                ? _buildEmptyState(colorScheme)
                        : !hasSearchResults && _searchQuery.isNotEmpty
                            ? _buildNoSearchResultsState(colorScheme)
                            : _buildContactsList(colorScheme, filteredContacts),
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

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search contacts...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsState(ColorScheme colorScheme) {
    return const EmptySearchState();
  }

  Widget _buildContactsList(ColorScheme colorScheme, List<UserDBISAR> contacts) {
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
    return ContactListTile(
      user: contact,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      showFavoriteStar: false,
      onTap: () {
        context.push(
          '/user-detail',
          extra: {'pubkey': contact.pubKey},
        );
      },
      onLongPress: () => _removeContact(contact.pubKey, contact.displayName()),
    );
  }
}

