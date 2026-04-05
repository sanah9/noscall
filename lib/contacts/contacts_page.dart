import 'package:flutter/material.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import 'package:noscall/core/call/contacts/contacts.dart';
import 'package:noscall/call/call_kit_manager.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/call/start_call_helper.dart';
import 'package:noscall/core/navigation/app_navigator_scope.dart';
import 'package:noscall/utils/router.dart';
import 'package:noscall/component/contact_list_tile.dart';
import 'package:noscall/component/empty_search_state.dart';
import 'package:noscall/component/search_bar.dart';
import 'package:noscall/utils/search_field_mixin.dart';
import 'contact_navigation_extension.dart';
import 'services/contact_navigation_service.dart';
import 'services/favorite_contacts_service.dart';
import 'services/contact_group_service.dart';
import 'models/contact_group_isar.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({
    super.key,
    this.initialShowFavoritesOnly = false,
    this.favoritesOnlyNavEntry = false,
  });

  /// When true, favorites filter starts selected (All / Favorites chips).
  final bool initialShowFavoritesOnly;

  /// True when this page is the root of the dedicated Favorites tab (mobile shell).
  final bool favoritesOnlyNavEntry;

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage>
    with SearchFieldMixin<ContactsPage> {
  final CallKitManager _callKitManager = CallKitManager.instance;
  final ContactGroupService _groupService = ContactGroupService.sharedInstance;
  final FavoriteContactsService _favService = FavoriteContactsService();
  late bool _showFavoritesOnly;
  List<ContactGroup> _groups = [];
  int? _selectedGroupId;
  Set<String>? _selectedGroupPubKeys;

  late ThemeData theme;
  Color get primary => theme.colorScheme.primary;
  Color get surface => theme.colorScheme.surface;
  Color get onSurface => theme.colorScheme.onSurface;
  Color get onSurfaceVariant => theme.colorScheme.onSurfaceVariant;
  Color get errorColor => theme.colorScheme.error;

  @override
  void initState() {
    super.initState();
    _showFavoritesOnly = widget.initialShowFavoritesOnly;
    initSearchField();
    // Clear group ID when on "All Contacts" page
    ContactNavigationService.sharedInstance.clearLastGroupId();
    _loadGroups();
    // Register callback to update UI when contacts change
    Contacts.sharedInstance.contactUpdatedCallBack = () {
      if (mounted) {
        setState(() {});
      }
    };
    _callKitManager.activeController?.then((_) {
      if (mounted) {
        setState(() {});
      }
    });
    _favService.favoritePubkeysNotifier.addListener(_onFavoritesChanged);
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadGroups() async {
    final groups = await _groupService.getAllGroups();
    if (mounted) setState(() => _groups = groups);
  }

  Future<void> _onGroupFilterChanged(int? groupId) async {
    if (groupId == null) {
      setState(() {
        _selectedGroupId = null;
        _selectedGroupPubKeys = null;
      });
      return;
    }
    final pubKeys = await _groupService.getGroupContactPubKeys(groupId);
    if (mounted) {
      setState(() {
        _selectedGroupId = groupId;
        _selectedGroupPubKeys = pubKeys.toSet();
      });
    }
  }

  @override
  void dispose() {
    _favService.favoritePubkeysNotifier.removeListener(_onFavoritesChanged);
    disposeSearchField();
    super.dispose();
  }

  Future<void> _startVoiceCall(String peerId, String displayName) async {
    await StartCallHelper.startCall(context, peerId: peerId, callType: CallType.audio);
  }

  Future<void> _startVideoCall(String peerId, String displayName) async {
    await StartCallHelper.startCall(context, peerId: peerId, callType: CallType.video);
  }

  List<UserDBISAR> _filterContacts(List<UserDBISAR> contacts) {
    var list = contacts;
    if (_selectedGroupPubKeys != null) {
      list = list.where((c) => _selectedGroupPubKeys!.contains(c.pubKey)).toList();
    }
    if (_showFavoritesOnly) {
      list = list.where((c) => _favService.isFavorite(c.pubKey)).toList();
    }
    if (searchQuery.isEmpty) return list;

    final query = searchQuery.toLowerCase();
    return list.where((contact) {
      final name = (contact.name ?? '').toLowerCase();
      final nickName = (contact.nickName ?? '').toLowerCase();

      return name.contains(query) || nickName.contains(query);
    }).toList();
  }

  /// Sort contacts: favorites first, then by display name.
  List<UserDBISAR> _sortContactsWithFavoritesFirst(List<UserDBISAR> contacts) {
    return List<UserDBISAR>.from(contacts)
      ..sort((a, b) {
        final aFav = _favService.isFavorite(a.pubKey);
        final bFav = _favService.isFavorite(b.pubKey);
        if (aFav != bFav) return aFav ? -1 : 1;
        return _getDisplayNameWithRemark(a)
            .toLowerCase()
            .compareTo(_getDisplayNameWithRemark(b).toLowerCase());
      });
  }

  bool _isNameMatched(UserDBISAR user) {
    if (searchQuery.isEmpty) return false;
    final query = searchQuery.toLowerCase();
    final name = (user.name ?? '').toLowerCase();
    return name.contains(query);
  }

  String _getDisplayNameWithRemark(UserDBISAR user) {
    final nickName = (user.nickName ?? '').trim();
    final name = (user.name ?? '').trim();
    final isNameMatched = _isNameMatched(user);
    
    if (isNameMatched && nickName.isNotEmpty && name.isNotEmpty) {
      return '$nickName($name)';
    } else if (nickName.isNotEmpty) {
      return nickName;
    } else if (name.isNotEmpty) {
      return name;
    } else {
      return user.shortEncodedPubkey;
    }
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    final allContacts = Contacts.sharedInstance.allContacts.values.toList();
    final filteredContacts =
        _sortContactsWithFavoritesFirst(_filterContacts(allContacts));
    final hasContacts = Contacts.sharedInstance.allContacts.isNotEmpty;
    final hasSearchResults = filteredContacts.isNotEmpty;
    
    return Scaffold(
      appBar: _buildAppBar(context),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            _buildSearchBar(),
            if (hasContacts) _buildFavoriteFilterChips(),
            if (hasContacts && _groups.isNotEmpty) _buildGroupFilterDropdown(),
            Expanded(
              child: !hasContacts
                  ? _buildEmptyContactsState(context)
                  : !hasSearchResults
                      ? (searchQuery.isNotEmpty
                          ? _buildNoSearchResultsState(context)
                          : _buildNoFavoritesOrGroupState(context))
                      : _buildContactsList(context, filteredContacts),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final canPopInner = Navigator.of(context).canPop();
    return AppBar(
      title: Text(widget.favoritesOnlyNavEntry ? 'Favorites' : 'Contacts'),
      centerTitle: true,
      backgroundColor: surface,
      foregroundColor: onSurface,
      elevation: 0,
      automaticallyImplyLeading: canPopInner,
      leading: canPopInner
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.popContactPage();
              },
            )
          : null,
      actions: [
        IconButton(
          padding: const EdgeInsets.only(right: 12),
          onPressed: () {
            // Use global router for add contact page
            AppRouter.router.push('/add-contact');
          },
          icon: const Icon(Icons.person_add),
          tooltip: 'Add Contact',
        ),
      ],
    );
  }

  Widget _buildEmptyContactsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Contacts',
            style: theme.textTheme.titleMedium?.copyWith(
              color: onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add contacts to start calling',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteFilterChips() {
    return _FavoriteFilterChips(
      showFavoritesOnly: _showFavoritesOnly,
      primary: primary,
      onPrimary: theme.colorScheme.onPrimary,
      onSelectAll: () => setState(() => _showFavoritesOnly = false),
      onSelectFavorites: () => setState(() => _showFavoritesOnly = true),
    );
  }

  Widget _buildGroupFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(
            'Group: ',
            style: theme.textTheme.bodyMedium?.copyWith(color: onSurfaceVariant),
          ),
          DropdownButton<int?>(
            value: _selectedGroupId,
            hint: const Text('All'),
            underline: const SizedBox.shrink(),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All'),
              ),
              ..._groups.map(
                (g) => DropdownMenuItem<int?>(
                  value: g.id,
                  child: Text(g.name),
                ),
              ),
            ],
            onChanged: _onGroupFilterChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNoFavoritesOrGroupState(BuildContext context) {
    if (_selectedGroupId != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No contacts in this group',
              style: theme.textTheme.titleMedium?.copyWith(
                color: onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add contacts to the group from the group detail page',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return _buildNoFavoritesState(context);
  }

  Widget _buildNoFavoritesState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_border,
            size: 64,
            color: onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No favorite contacts',
            style: theme.textTheme.titleMedium?.copyWith(
              color: onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add contacts to favorites from their profile',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return SearchTextField(
      controller: searchController,
      hintText: 'Search contacts...',
    );
  }

  Widget _buildNoSearchResultsState(BuildContext context) {
    return const EmptySearchState();
  }

  Widget _buildContactsList(BuildContext context, List<UserDBISAR> contacts) {
    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return _buildContactCard(context, contact);
      },
    );
  }

  Widget _buildContactCard(BuildContext context, UserDBISAR contact) {
    return ContactListTile(
      user: contact,
      searchQuery: searchQuery.isEmpty ? null : searchQuery,
      onTap: () {
        AppNavigatorScope.requireOf(context).pushUserDetail(context, contact.pubKey);
      },
      onCallVoice: () => _startVoiceCall(contact.pubKey, contact.displayName()),
      onCallVideo: () => _startVideoCall(contact.pubKey, contact.displayName()),
      showFavoriteStar: true,
    );
  }
}

/// All / Favorites filter chips for contacts list.
class _FavoriteFilterChips extends StatelessWidget {
  const _FavoriteFilterChips({
    required this.showFavoritesOnly,
    required this.primary,
    required this.onPrimary,
    required this.onSelectAll,
    required this.onSelectFavorites,
  });

  final bool showFavoritesOnly;
  final Color primary;
  final Color onPrimary;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectFavorites;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: !showFavoritesOnly,
            onSelected: (_) => onSelectAll(),
          ),
          const SizedBox(width: 8),
          FilterChip(
            avatar: Icon(
              Icons.star,
              size: 18,
              color: showFavoritesOnly ? onPrimary : primary,
            ),
            label: const Text('Favorites'),
            selected: showFavoritesOnly,
            showCheckmark: false,
            onSelected: (_) => onSelectFavorites(),
          ),
        ],
      ),
    );
  }
}