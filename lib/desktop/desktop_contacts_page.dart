import 'package:flutter/material.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import 'package:noscall/core/call/contacts/contacts.dart';
import 'package:noscall/call/call_manager.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/utils/toast.dart';
import 'package:noscall/contacts/user_avatar.dart';
import 'package:noscall/contacts/services/favorite_contacts_service.dart';
import 'desktop_page_wrapper.dart';
import 'desktop_navigator.dart';

class DesktopContactsPage extends StatefulWidget {
  const DesktopContactsPage({super.key});

  @override
  State<DesktopContactsPage> createState() => _DesktopContactsPageState();
}

class _DesktopContactsPageState extends State<DesktopContactsPage> {
  final CallKitManager _callKitManager = CallKitManager();
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
    if (_callKitManager.hasActiveCalling) {
      if (mounted) AppToast.showInfo(context, 'Call already in progress');
      return;
    }

    try {
      if (mounted) AppToast.showInfo(context, 'Starting voice call...');
      final controller = await _callKitManager.startCall(
        peerId: peerId,
        callType: CallType.audio,
      );

      if (mounted) {
        if (controller == null) {
          AppToast.showError(context, 'Failed to start voice call');
        } else {
          AppToast.showSuccess(context, 'Voice call started');
        }
      }
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Voice call failed';
      if (e.toString().contains('Maximum concurrent calls reached')) {
        errorMessage = 'Another call is already in progress';
      } else if (e.toString().contains('Required permissions not granted')) {
        errorMessage = 'Microphone permission required for voice calls';
      }
      AppToast.showError(context, errorMessage);
    }
  }

  Future<void> _startVideoCall(String peerId) async {
    if (_callKitManager.hasActiveCalling) {
      if (mounted) AppToast.showInfo(context, 'Call already in progress');
      return;
    }

    try {
      if (mounted) AppToast.showInfo(context, 'Starting video call...');
      final controller = await _callKitManager.startCall(
        peerId: peerId,
        callType: CallType.video,
      );

      if (mounted) {
        if (controller == null) {
          AppToast.showError(context, 'Failed to start video call');
        } else {
          AppToast.showSuccess(context, 'Video call started');
        }
      }
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Video call failed';
      if (e.toString().contains('Maximum concurrent calls reached')) {
        errorMessage = 'Another call is already in progress';
      } else if (e.toString().contains('Required permissions not granted')) {
        errorMessage = 'Camera and microphone permissions required';
      }
      AppToast.showError(context, errorMessage);
    }
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
                ? _buildEmptyState(theme, colorScheme, 'No contacts yet')
                : !hasResults
                    ? Center(
                        child: _buildEmptyState(
                          theme,
                          colorScheme,
                          _searchQuery.isNotEmpty
                              ? 'No results found'
                              : 'No favorite contacts',
                          subtitle: _showFavoritesOnly && _searchQuery.isEmpty
                              ? 'Add contacts to favorites from their profile'
                              : null,
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
                          return _ContactItem(
                            contact: contact,
                            onTap: () {
                              final navigatorState = DesktopNavigatorProvider.of(context);
                              navigatorState?.navigateToContactDetail(contact.pubKey);
                            },
                            onVoiceCall: () => _startVoiceCall(contact.pubKey),
                            onVideoCall: () => _startVideoCall(contact.pubKey),
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

  Widget _buildEmptyState(
    ThemeData theme,
    ColorScheme colorScheme,
    String message, {
    String? subtitle,
    IconData icon = Icons.contacts_outlined,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final UserDBISAR contact;
  final VoidCallback onTap;
  final VoidCallback onVoiceCall;
  final VoidCallback onVideoCall;

  const _ContactItem({
    required this.contact,
    required this.onTap,
    required this.onVoiceCall,
    required this.onVideoCall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fav = FavoriteContactsService();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              UserAvatar(
                user: contact,
                size: 48,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.displayName(),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'npub${contact.pubKey.substring(0, 8)}...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<Set<String>>(
                valueListenable: fav.favoritePubkeysNotifier,
                builder: (context, favoritePubkeys, _) {
                  final isFav = favoritePubkeys.contains(contact.pubKey);
                  return IconButton(
                    icon: Icon(isFav ? Icons.star : Icons.star_border),
                    onPressed: () => fav.toggleFavorite(contact.pubKey),
                    color: isFav ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    tooltip: isFav ? 'Remove from Favorites' : 'Add to Favorites',
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.phone),
                onPressed: onVoiceCall,
                color: colorScheme.primary,
                tooltip: 'Voice call',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.videocam),
                onPressed: onVideoCall,
                color: colorScheme.primary,
                tooltip: 'Video call',
              ),
            ],
          ),
        ),
      ),
    );
  }
}