import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import 'package:noscall/core/navigation/app_navigator_scope.dart';
import 'package:noscall/core/call/contacts/contacts.dart';
import 'package:noscall/core/call/contacts/contacts+blocklist.dart';
import 'package:noscall/contacts/services/contact_group_service.dart';
import 'package:noscall/contacts/services/contact_navigation_service.dart';
import 'package:noscall/contacts/contact_navigation_extension.dart';
import 'package:noscall/component/contact_list_tile.dart';
import 'package:noscall/component/empty_search_state.dart';
import 'package:noscall/component/search_bar.dart';
import 'package:noscall/utils/search_field_mixin.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/call/start_call_helper.dart';
import 'package:noscall/utils/toast.dart';

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

class _GroupContactsPageState extends State<GroupContactsPage>
    with SearchFieldMixin<GroupContactsPage> {
  final ContactGroupService _groupService = ContactGroupService.sharedInstance;
  List<String> _contactPubKeys = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initSearchField();
    ContactNavigationService.sharedInstance.saveLastGroupId(widget.groupId);
    _loadContacts();
  }

  @override
  void dispose() {
    disposeSearchField();
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
    if (searchQuery.isEmpty) return contacts;

    final query = searchQuery.toLowerCase();
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
    final orphanMemberCount = _contactPubKeys.length - contacts.length;
    final filteredContacts = _filterContacts(contacts);
    final hasContacts = contacts.isNotEmpty;
    final hasSearchResults = filteredContacts.isNotEmpty;
    final hasOrphansOnly =
        !_isLoading && contacts.isEmpty && _contactPubKeys.isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
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
              if (!_isLoading) _buildSearchBar(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : hasOrphansOnly
                        ? _buildOrphanOnlyState(theme, colorScheme)
                        : !hasContacts
                            ? _buildEmptyState(theme, colorScheme)
                            : !hasSearchResults && searchQuery.isNotEmpty
                                ? _buildNoSearchResultsState(colorScheme)
                                : _buildContactsList(
                                    theme,
                                    colorScheme,
                                    filteredContacts,
                                    orphanMemberCount,
                                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
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
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add people from your address book to call them from here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _addContacts,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Add contacts'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrphanOnlyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No matching contacts',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Everyone in this group is missing from your address book. '
              'They may have been removed, or data is still syncing.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SearchTextField(
      controller: searchController,
      hintText: 'Search contacts...',
    );
  }

  Widget _buildNoSearchResultsState(ColorScheme colorScheme) {
    return const EmptySearchState();
  }

  Widget _buildContactsList(
    ThemeData theme,
    ColorScheme colorScheme,
    List<UserDBISAR> contacts,
    int orphanMemberCount,
  ) {
    if (contacts.isEmpty) {
      return _buildEmptyState(theme, colorScheme);
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: contacts.length + (orphanMemberCount > 0 ? 1 : 0),
      itemBuilder: (context, index) {
        if (orphanMemberCount > 0 && index == 0) {
          return Material(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
            child: ListTile(
              dense: true,
              leading: Icon(
                Icons.info_outline,
                color: colorScheme.primary,
                size: 22,
              ),
              title: Text(
                orphanMemberCount == 1
                    ? '1 member is not in your address book and is hidden.'
                    : '$orphanMemberCount members are not in your address book and are hidden.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }
        final contactIndex = orphanMemberCount > 0 ? index - 1 : index;
        final contact = contacts[contactIndex];
        return _buildContactCard(context, contact, colorScheme);
      },
    );
  }

  Future<void> _startVoiceCall(String pubKey) async {
    if (Contacts.sharedInstance.inBlockList(pubKey)) {
      AppToast.showError(context, 'Cannot call blocked user');
      return;
    }
    await StartCallHelper.startCall(context, peerId: pubKey, callType: CallType.audio);
  }

  Future<void> _startVideoCall(String pubKey) async {
    if (Contacts.sharedInstance.inBlockList(pubKey)) {
      AppToast.showError(context, 'Cannot call blocked user');
      return;
    }
    await StartCallHelper.startCall(context, peerId: pubKey, callType: CallType.video);
  }

  Widget _buildContactCard(
      BuildContext context, UserDBISAR contact, ColorScheme colorScheme) {
    return ContactListTile(
      user: contact,
      searchQuery: searchQuery.isEmpty ? null : searchQuery,
      showFavoriteStar: false,
      onTap: () {
        AppNavigatorScope.requireOf(context).pushUserDetail(context, contact.pubKey);
      },
      onLongPress: () => _removeContact(contact.pubKey, contact.displayName()),
      onCallVoice: () => _startVoiceCall(contact.pubKey),
      onCallVideo: () => _startVideoCall(contact.pubKey),
    );
  }
}

