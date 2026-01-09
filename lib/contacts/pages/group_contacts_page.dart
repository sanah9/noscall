import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import 'package:noscall/core/account/account.dart' as ChatCore;
import '../../core/call/contacts/contacts.dart';
import '../services/contact_group_service.dart';
import '../services/contact_navigation_service.dart';
import '../contact_navigation_extension.dart';
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

  Widget _buildHighlightedText(String text, String query, ThemeData theme, ColorScheme colorScheme) {
    if (query.isEmpty) {
      return Text(text);
    }

    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (start < text.length) {
      final index = textLower.indexOf(queryLower, start);
      if (index == -1) {
        if (start < text.length) {
          spans.add(TextSpan(
            text: text.substring(start),
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ));
        }
        break;
      }

      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ));

      start = index + query.length;
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  List<TextSpan> _buildHighlightedSpans(String text, String query, ThemeData theme, ColorScheme colorScheme) {
    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (start < text.length) {
      final index = textLower.indexOf(queryLower, start);
      if (index == -1) {
        if (start < text.length) {
          spans.add(TextSpan(
            text: text.substring(start),
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ));
        }
        break;
      }

      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ));

      start = index + query.length;
    }

    return spans;
  }

  Widget _buildHighlightedTextWithRemark(String nickName, String name, ThemeData theme, ColorScheme colorScheme) {
    final query = _searchQuery.toLowerCase();
    final nameLower = name.toLowerCase();
    
    if (nameLower.contains(query)) {
      final spans = <TextSpan>[];
      
      spans.add(TextSpan(
        text: '$nickName(',
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ));
      
      final nameSpans = _buildHighlightedSpans(name, query, theme, colorScheme);
      spans.addAll(nameSpans);
      
      spans.add(TextSpan(
        text: ')',
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ));
      
      return RichText(
        text: TextSpan(children: spans),
      );
    } else {
      return Text(
        nickName,
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      );
    }
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
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
            onLongPress: () {
              _removeContact(contact.pubKey, updatedUser.displayName());
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
                        _buildContactName(updatedUser, theme, colorScheme),
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

  Widget _buildContactName(UserDBISAR user, ThemeData theme, ColorScheme colorScheme) {
    if (_searchQuery.isNotEmpty) {
      final nickName = (user.nickName ?? '').trim();
      final name = (user.name ?? '').trim();
      final isNameMatched = _isNameMatched(user);
      final query = _searchQuery.toLowerCase();
      final nickNameLower = nickName.toLowerCase();
      final isNickNameMatched = nickNameLower.contains(query);
      
      if (isNameMatched && nickName.isNotEmpty && name.isNotEmpty) {
        return _buildHighlightedTextWithRemark(nickName, name, theme, colorScheme);
      } else if (isNickNameMatched && nickName.isNotEmpty) {
        return _buildHighlightedText(nickName, _searchQuery, theme, colorScheme);
      } else if (name.isNotEmpty) {
        return _buildHighlightedText(name, _searchQuery, theme, colorScheme);
      } else {
        return Text(
          user.shortEncodedPubkey,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        );
      }
    }
    
    final displayText = _getDisplayNameWithRemark(user);
    return Text(
      displayText,
      style: theme.textTheme.titleMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

