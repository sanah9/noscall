import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/toast.dart';
import '../core/account/account.dart';
import '../core/account/account+profile.dart';
import '../core/account/model/userDB_isar.dart';

class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<UserDBISAR> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: _buildAppBar(context, colorScheme),
      body: Column(
        children: [
          _buildSearchSection(context, theme, colorScheme),
          _buildSearchResults(context, theme, colorScheme),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ColorScheme colorScheme) {
    return AppBar(
      title: const Text('Add Contact'),
      centerTitle: true,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search by npub or DNS',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildSearchInputRow(context, theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildSearchInputRow(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildSearchTextField(theme, colorScheme),
        ),
        const SizedBox(width: 12),
        _buildSearchButton(colorScheme),
      ],
    );
  }

  Widget _buildSearchTextField(ThemeData theme, ColorScheme colorScheme) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Enter npub (e.g., npub1abc...) or DNS (e.g., user@domain.com)',
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: colorScheme.onSurfaceVariant,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: _clearSearch,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      onSubmitted: _searchUser,
    );
  }

  Widget _buildSearchButton(ColorScheme colorScheme) {
    return ElevatedButton(
      onPressed: _isSearching
          ? null
          : () => _searchUser(_searchController.text),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
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
                  colorScheme.onPrimary,
                ),
              ),
            )
          : const Text('Search'),
    );
  }

  Widget _buildSearchResults(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Expanded(
      child: _searchResults.isEmpty
          ? _buildEmptyState(theme, colorScheme)
          : _buildResultsList(context, theme, colorScheme),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Search for users by npub or DNS',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a valid npub or DNS to find and add contacts',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserCard(context, user, theme, colorScheme);
      },
    );
  }

  Widget _buildUserCard(BuildContext context, UserDBISAR user, ThemeData theme, ColorScheme colorScheme) {
    final displayName = user.getUserShowName();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: _buildUserAvatar(displayName, colorScheme),
        title: Text(
          displayName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: _buildUserSubtitle(user, theme, colorScheme),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: colorScheme.onSurfaceVariant,
          size: 16,
        ),
        onTap: () {
          context.push(
            '/user-detail',
            extra: user.pubKey,
          );
        },
      ),
    );
  }

  Widget _buildUserAvatar(String displayName, ColorScheme colorScheme) {
    return CircleAvatar(
      backgroundColor: colorScheme.primary,
      child: Text(
        displayName[0].toUpperCase(),
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUserSubtitle(UserDBISAR user, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.encodedPubkey,
          style: theme.textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            color: colorScheme.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (user.dns?.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Text(
            user.dns!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }


  void _searchUser(String query) async {
    query = query.trim();
    if (query.isEmpty) {
      AppToast.showError('Please enter a valid npub or DNS');
      return;
    }

    // Check if query is npub or DNS format
    final isPubkeyFormat = query.startsWith('npub');
    final isDnsFormat = query.contains('@');

    if (!isPubkeyFormat && !isDnsFormat) {
      AppToast.showError('Please enter a valid npub or DNS format');
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
        ) ??
            '';
      }

      if (pubkey.isEmpty) {
        setState(() {
          _isSearching = false;
        });
        AppToast.showError('Invalid npub or DNS format');
        return;
      }

      // Validate pubkey format
      if (!Account.sharedInstance.isValidPubKey(pubkey)) {
        setState(() {
          _isSearching = false;
        });
        AppToast.showError('Invalid pubkey format');
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
        AppToast.showInfo('No user found');
      } else {
        AppToast.showSuccess('User found');
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });

      if (e.toString().contains('timeout')) {
        AppToast.showError('Search timeout - please try again');
      } else {
        AppToast.showError('Search failed: $e');
      }
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults.clear();
    });
  }
}
