import 'package:flutter/material.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import 'package:noscall/core/call/contacts/contacts.dart';
import 'package:noscall/call/call_manager.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/call/start_call_helper.dart';
import 'package:noscall/utils/toast.dart';
import 'package:noscall/component/contact_list_tile.dart';
import 'package:noscall/component/empty_search_state.dart';
import 'package:noscall/contacts/services/favorite_contacts_service.dart';
import 'desktop_page_wrapper.dart';
import 'desktop_navigator.dart';

class DesktopContactsPage extends StatefulWidget {
  const DesktopContactsPage({super.key});

  @override
  State<DesktopContactsPage> createState() => _DesktopContactsPageState();
}

class _DesktopContactsPageState extends State<DesktopContactsPage> {
  final CallKitManager _callKitManager = CallKitManager.instance;
  final TextEditingController _searchController = TextEditingController();
  final FavoriteContactsService _favService = FavoriteContactsService();
  String _searchQuery = '';
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    Contacts.sharedInstance.contactUpdatedCallBack = () {
      if (mounted) setState(() {});
    };
    _favService.favoritePubkeysNotifier.addListener(_onFavoritesChanged);

    _callKitManager.activeController?.then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _favService.favoritePubkeysNotifier.removeListener(_onFavoritesChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<UserDBISAR> _filterContacts(List<UserDBISAR> contacts) {
    var list = contacts;
    if (_showFavoritesOnly) {
      list = list.where((c) => _favService.isFavorite(c.pubKey)).toList();
    }
    if (_searchQuery.isEmpty) return list;
    return list.where((contact) {
      final name = (contact.name ?? '').toLowerCase();
      final displayName = contact.displayName().toLowerCase();
      return name.contains(_searchQuery) || displayName.contains(_searchQuery);
    }).toList();
  }

  List<UserDBISAR> _sortContactsWithFavoritesFirst(List<UserDBISAR> contacts) {
    return List<UserDBISAR>.from(contacts)
      ..sort((a, b) {
        final aFav = _favService.isFavorite(a.pubKey);
        final bFav = _favService.isFavorite(b.pubKey);
        if (aFav != bFav) return aFav ? -1 : 1;
        return a.displayName().toLowerCase().compareTo(b.displayName().toLowerCase());
      });
  }

  Future<void> _startVoiceCall(String peerId) async {
    await StartCallHelper.startCall(context, peerId: peerId, callType: CallType.audio);
  }

  Future<void> _startVideoCall(String peerId) async {
    await StartCallHelper.startCall(context, peerId: peerId, callType: CallType.video);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final allContacts = Contacts.sharedInstance.allContacts.values.toList();
    final filteredContacts = _sortContactsWithFavoritesFirst(_filterContacts(allContacts));
    final hasContacts = allContacts.isNotEmpty;
    final hasResults = filteredContacts.isNotEmpty;

    return DesktopPageWrapper(
      title: 'Contacts',
      trailing: DesktopSearchBar(
        controller: _searchController,
        hintText: 'Search...',
        onChanged: _onSearchChanged,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasContacts) _buildFavoriteFilterChips(theme, colorScheme),
          Expanded(
            child: !hasContacts
                ? EmptySearchState(
                    title: 'No contacts yet',
                    subtitle: 'Add contacts to get started',
                    icon: Icons.people_outline,
                  )
                : !hasResults
                    ? Center(
                        child: EmptySearchState(
                          title: _searchQuery.isNotEmpty
                              ? 'No results found'
                              : 'No favorite contacts',
                          subtitle: _showFavoritesOnly && _searchQuery.isEmpty
                              ? 'Add contacts to favorites from their profile'
                              : 'Try a different search term',
                          icon: _showFavoritesOnly && _searchQuery.isEmpty
                              ? Icons.star_border
                              : Icons.contacts_outlined,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = filteredContacts[index];
                          final navigatorState = DesktopNavigatorProvider.of(context);
                          return ContactListTile(
                            user: contact,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            onTap: () => navigatorState?.navigateToContactDetail(contact.pubKey),
                            onCallVoice: () => _startVoiceCall(contact.pubKey),
                            onCallVideo: () => _startVideoCall(contact.pubKey),
                            showFavoriteStar: true,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteFilterChips(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: !_showFavoritesOnly,
            onSelected: (_) => setState(() => _showFavoritesOnly = false),
          ),
          const SizedBox(width: 8),
          FilterChip(
            avatar: Icon(
              Icons.star,
              size: 18,
              color: _showFavoritesOnly ? colorScheme.onPrimary : colorScheme.primary,
            ),
            label: const Text('Favorites'),
            selected: _showFavoritesOnly,
            onSelected: (_) => setState(() => _showFavoritesOnly = true),
          ),
        ],
      ),
    );
  }

}