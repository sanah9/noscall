import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import 'package:noscall/core/call/contacts/contacts.dart';
import 'package:noscall/call/call_manager.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/call/start_call_helper.dart';
import 'package:noscall/core/navigation/app_navigator_scope.dart';
import 'package:noscall/utils/router.dart';
import 'package:noscall/component/contact_list_tile.dart';
import 'package:noscall/component/empty_search_state.dart';
import 'contact_navigation_extension.dart';
import 'services/contact_navigation_service.dart';
import 'services/favorite_contacts_service.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final CallKitManager _callKitManager = CallKitManager.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showFavoritesOnly = false;

  late ThemeData theme;
  Color get primary => theme.colorScheme.primary;
  Color get surface => theme.colorScheme.surface;
  Color get onSurface => theme.colorScheme.onSurface;
  Color get onSurfaceVariant => theme.colorScheme.onSurfaceVariant;
  Color get errorColor => theme.colorScheme.error;

  @override
  void initState() {
    super.initState();
    // Clear group ID when on "All Contacts" page
    ContactNavigationService.sharedInstance.clearLastGroupId();
    
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

  Future<void> _startVoiceCall(String peerId, String displayName) async {
    await StartCallHelper.startCall(context, peerId: peerId, callType: CallType.audio);
  }

  Future<void> _startVideoCall(String peerId, String displayName) async {
    await StartCallHelper.startCall(context, peerId: peerId, callType: CallType.video);
  }

  List<UserDBISAR> _filterContacts(List<UserDBISAR> contacts) {
    var list = contacts;
    if (_showFavoritesOnly) {
      final fav = FavoriteContactsService();
      list = list.where((c) => fav.isFavorite(c.pubKey)).toList();
    }
    if (_searchQuery.isEmpty) return list;

    final query = _searchQuery.toLowerCase();
    return list.where((contact) {
      final name = (contact.name ?? '').toLowerCase();
      final nickName = (contact.nickName ?? '').toLowerCase();
      
      return name.contains(query) || nickName.contains(query);
    }).toList();
  }

  /// Sort contacts: favorites first, then by display name.
  List<UserDBISAR> _sortContactsWithFavoritesFirst(List<UserDBISAR> contacts) {
    final fav = FavoriteContactsService();
    return List<UserDBISAR>.from(contacts)
      ..sort((a, b) {
        final aFav = fav.isFavorite(a.pubKey);
        final bFav = fav.isFavorite(b.pubKey);
        if (aFav != bFav) return aFav ? -1 : 1;
        return _getDisplayNameWithRemark(a)
            .toLowerCase()
            .compareTo(_getDisplayNameWithRemark(b).toLowerCase());
      });
  }

  bool _isNameMatched(UserDBISAR user) {
    if (_searchQuery.isEmpty) return false;
    final query = _searchQuery.toLowerCase();
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
            Expanded(
              child: !hasContacts
                  ? _buildEmptyContactsState(context)
                  : !hasSearchResults
                      ? (_searchQuery.isNotEmpty
                          ? _buildNoSearchResultsState(context)
                          : _buildNoFavoritesState(context))
                      : _buildContactsList(context, filteredContacts),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Contacts'),
      centerTitle: true,
      backgroundColor: surface,
      foregroundColor: onSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          // Pop back to group list page - same API as global router
          context.popContactPage();
        },
      ),
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
    return _ContactsSearchBar(
      controller: _searchController,
      hasQuery: _searchQuery.isNotEmpty,
      surface: surface,
      onSurfaceVariant: onSurfaceVariant,
      primary: primary,
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
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      onTap: () {
        AppNavigatorScope.requireOf(context).pushUserDetail(context, contact.pubKey);
      },
      onCallVoice: () => _startVoiceCall(contact.pubKey, contact.displayName()),
      onCallVideo: () => _startVideoCall(contact.pubKey, contact.displayName()),
      showFavoriteStar: true,
    );
  }
}

/// Reusable search bar for contacts list.
class _ContactsSearchBar extends StatelessWidget {
  const _ContactsSearchBar({
    required this.controller,
    required this.hasQuery,
    required this.surface,
    required this.onSurfaceVariant,
    required this.primary,
  });

  final TextEditingController controller;
  final bool hasQuery;
  final Color surface;
  final Color onSurfaceVariant;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        border: Border(
          bottom: BorderSide(
            color: onSurfaceVariant.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search contacts...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: hasQuery
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => controller.clear(),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: onSurfaceVariant.withValues(alpha: 0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: onSurfaceVariant.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primary, width: 2),
          ),
          filled: true,
          fillColor: onSurfaceVariant.withValues(alpha: 0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
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