import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/contacts/user_avatar.dart';
import '../utils/toast.dart';
import '../core/account/account.dart';
import '../core/account/account+profile.dart';
import '../core/account/model/userDB_isar.dart';
import '../core/call/contacts/contacts.dart';

class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final List<UserDBISAR> _searchResults = [];
  final List<UserDBISAR> _followerSuggestions = [];
  bool _isSearching = false;
  bool _isLoadingFollowers = true;

  late ThemeData theme;
  Color get surface => theme.colorScheme.surface;
  Color get onSurface => theme.colorScheme.onSurface;
  Color get onSurfaceVariant => theme.colorScheme.onSurfaceVariant;
  Color get primary => theme.colorScheme.primary;
  Color get onPrimary => theme.colorScheme.onPrimary;
  Color get outline => theme.colorScheme.outline;

  bool get _isSearchMode {
    final query = _searchController.text.trim();
    if (_isSearching) return true;
    if (query.isEmpty) return false;
    if (_searchFocusNode.hasFocus) return true;
    if (_searchResults.isNotEmpty) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchTextChanged);
    _searchFocusNode.addListener(_handleSearchFocusChanged);
    _loadFollowerSuggestions();
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchTextChanged);
    _searchFocusNode.removeListener(_handleSearchFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearchTextChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleSearchFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadFollowerSuggestions() async {
    try {
      final followers = Account.sharedInstance.me?.followingList ?? [];
      if (followers.isEmpty) return;

      final contacts = Contacts.sharedInstance.allContacts;
      final seen = <String>{};
      final filteredPubkeys = <String>[];
      for (final pubkey in followers) {
        final normalized = pubkey.trim();
        if (normalized.isEmpty) continue;
        if (contacts.containsKey(normalized)) continue;
        if (seen.add(normalized)) {
          filteredPubkeys.add(normalized);
        }
      }
      if (filteredPubkeys.isEmpty) return;

      const suggestionLimit = 50;
      final limitedPubkeys = filteredPubkeys.take(suggestionLimit).toList();

      final users = await Future.wait(
        limitedPubkeys.map((pubkey) async {
          final user = await Account.sharedInstance.getUserInfo(pubkey);
          return user;
        }),
      );

      final suggestions = users.whereType<UserDBISAR>().toList()
        ..sort(
              (a, b) => a
              .displayName()
              .toLowerCase()
              .compareTo(b.displayName().toLowerCase()),
        );

      _followerSuggestions.addAll(suggestions);
    } finally {
      _isLoadingFollowers = false;
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    return Scaffold(
      appBar: _buildAppBar(context),
      body: GestureDetector(
        onTap: _dismissKeyboard,
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            _buildSearchSection(context),
            Expanded(
              child: _buildMainContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final child = _isSearchMode
        ? _buildSearchResults(context)
        : _buildFollowersSection(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(
        key: ValueKey<bool>(_isSearchMode),
        child: child,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Add Contact'),
      centerTitle: true,
      backgroundColor: surface,
      foregroundColor: onSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          _dismissKeyboard();
          context.pop();
        },
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Search by npub or DNS',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: _buildSearchInputRow(context),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: _buildSearchButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInputRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSearchTextField(),
        ),
        const SizedBox(width: 12),
        _buildScanButton(),
      ],
    );
  }

  Widget _buildSearchTextField() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText:
        'Enter npub (e.g., npub1abc...) or DNS (e.g., user@domain.com)',
        hintStyle: TextStyle(
          color: onSurfaceVariant,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: onSurfaceVariant,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
          icon: Icon(
            Icons.clear,
            color: onSurfaceVariant,
          ),
          onPressed: _clearSearch,
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primary,
            width: 2,
          ),
        ),
      ),
      onSubmitted: (value) {
        _dismissKeyboard();
        _searchUser(value);
      },
    );
  }

  Widget _buildScanButton() {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: outline,
        ),
      ),
      child: IconButton(
        onPressed: () => _navigateToScanPage(),
        icon: Icon(
          Icons.qr_code_scanner,
          color: onSurface,
        ),
        tooltip: 'Scan QR Code',
      ),
    );
  }

  Widget _buildSearchButton() {
    return ElevatedButton(
      onPressed:
      _isSearching ? null : () => _searchUser(_searchController.text),
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isSearching
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            onPrimary,
          ),
        ),
      )
          : const Text('Search'),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    if (_isSearching) {
      return const SizedBox();
    }

    if (_searchResults.isEmpty) {
      return _buildSearchEmptyState(context);
    }

    return _buildResultsList(context, _searchResults);
  }

  Widget _buildFollowersSection(BuildContext context) {
    if (_isLoadingFollowers) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primary),
        ),
      );
    }

    if (_followerSuggestions.isEmpty) {
      return _buildEmptyFollowersState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'People you may know',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
        ),
        Expanded(
          child: _buildResultsList(context, _followerSuggestions),
        ),
      ],
    );
  }

  Widget _buildSearchEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Search for users by npub or DNS',
            style: theme.textTheme.titleMedium?.copyWith(
              color: onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a valid npub or DNS to find and add contacts',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFollowersState(BuildContext context) {
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
            'No followers to suggest',
            style: theme.textTheme.titleMedium?.copyWith(
              color: onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Followers you are not already connected with will appear here',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(BuildContext context, List<UserDBISAR> users) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollStartNotification) {
          _dismissKeyboard();
        }
        return false;
      },
      child: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildUserCard(context, user);
        },
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserDBISAR user) {
    final displayName = user.displayName();
    return ListTile(
      leading: UserAvatar(user: user),
      title: Text(
        displayName,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: _buildUserSubtitle(context, user),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: onSurfaceVariant,
        size: 16,
      ),
      onTap: () async {
        _dismissKeyboard();

        final pubkey = user.pubKey;
        await context.push(
          '/user-detail',
          extra: {'pubkey': pubkey},
        );
        if (!mounted) return;

        final isContact =
        Contacts.sharedInstance.allContacts.containsKey(pubkey);
        if (isContact) {
          _followerSuggestions.remove(user);
        }
      },
    );
  }

  Widget _buildUserSubtitle(BuildContext context, UserDBISAR user) {
    return Text(
      user.encodedPubkey,
      style: theme.textTheme.bodySmall?.copyWith(
        fontFamily: 'monospace',
        color: onSurfaceVariant,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _searchUser(String query) async {
    _dismissKeyboard();
    query = query.trim();
    if (query.isEmpty) {
      AppToast.showError(context, 'Please enter a valid npub or DNS');
      return;
    }

    // Check if query is npub or DNS format
    final isPubkeyFormat = query.startsWith('npub');
    final isDnsFormat = query.contains('@');

    if (!isPubkeyFormat && !isDnsFormat) {
      AppToast.showError(context, 'Please enter a valid npub or DNS format');
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults.clear();
    });

    try {
      String pubkey = '';
      if (isPubkeyFormat) {
        pubkey = UserDBISAR.decodePubkey(query) ?? '';
      } else if (isDnsFormat) {
        pubkey = await Account.getDNSPubkey(
          query.substring(0, query.indexOf('@')),
          query.substring(query.indexOf('@') + 1),
        ) ?? '';
      }

      if (pubkey.isEmpty) {
        setState(() {
          _isSearching = false;
        });
        AppToast.showError(context, 'Invalid npub or DNS format');
        return;
      }

      // Validate pubkey format
      if (!Account.sharedInstance.isValidPubKey(pubkey)) {
        setState(() {
          _isSearching = false;
        });
        AppToast.showError(context, 'Invalid pubkey format');
        return;
      }

      // Search user profile from relay with 15s timeout
      final user = await Account.sharedInstance.reloadProfileFromRelay(pubkey)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Search timeout');
            },
          );

      setState(() {
        _searchResults.clear();
        _searchResults.add(user);
        _isSearching = false;
      });

      if (_searchResults.isEmpty) {
        AppToast.showInfo(context, 'No user found');
      } else {
        AppToast.showSuccess(context, 'User found');
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });

      if (e.toString().contains('timeout')) {
        AppToast.showError(context, 'Search timeout - please try again');
      } else {
        AppToast.showError(context, 'Search failed: $e');
      }
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults.clear();
    });
    _dismissKeyboard();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _navigateToScanPage() async {
    _dismissKeyboard();

    final result = await context.push<String>('/qr-scan');

    if (result != null && result.isNotEmpty) {
      // Set the scanned text to the search controller
      _searchController.text = result;

      // Trigger search automatically
      _searchUser(result);
    }
  }
}