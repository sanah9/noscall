import 'package:flutter/material.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import 'package:noscall/core/account/account.dart' as ChatCore;
import '../core/call/contacts/contacts.dart';
import '../call/call_manager.dart';
import '../call/constant/call_type.dart';
import '../utils/toast.dart';
import '../utils/router.dart';
import 'user_avatar.dart';
import 'contact_navigation_extension.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final CallKitManager _callKitManager = CallKitManager();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late ThemeData theme;
  Color get primary => theme.colorScheme.primary;
  Color get surface => theme.colorScheme.surface;
  Color get onSurface => theme.colorScheme.onSurface;
  Color get onSurfaceVariant => theme.colorScheme.onSurfaceVariant;
  Color get errorColor => theme.colorScheme.error;

  @override
  void initState() {
    super.initState();
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
    if (_callKitManager.hasActiveCalling) {
      AppToast.showInfo(context, 'Call already in progress');
      return;
    }

    try {
      AppToast.showInfo(context, 'Starting voice call...');

      final controller = await _callKitManager.startCall(
        peerId: peerId,
        callType: CallType.audio,
      );

      if (controller == null) {
        AppToast.showError(context, 'Failed to start voice call');
      } else {
        AppToast.showSuccess(context, 'Voice call started');
      }
    } catch (e) {
      String errorMessage = 'Voice call failed';
      if (e.toString().contains('Maximum concurrent calls reached')) {
        errorMessage = 'Another call is already in progress';
      } else if (e.toString().contains('Required permissions not granted')) {
        errorMessage = 'Microphone permission required for voice calls';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Please check app settings';
      }
      AppToast.showError(context, errorMessage);
    }
  }

  Future<void> _startVideoCall(String peerId, String displayName) async {
    if (_callKitManager.hasActiveCalling) {
      AppToast.showInfo(context, 'Call already in progress');
      return;
    }

    try {
      AppToast.showInfo(context, 'Starting video call...');

      final controller = await _callKitManager.startCall(
        peerId: peerId,
        callType: CallType.video,
      );

      if (controller == null) {
        AppToast.showError(context, 'Failed to start video call');
      } else {
        AppToast.showSuccess(context, 'Video call started');
      }
    } catch (e) {
      String errorMessage = 'Video call failed';
      if (e.toString().contains('Maximum concurrent calls reached')) {
        errorMessage = 'Another call is already in progress';
      } else if (e.toString().contains('Required permissions not granted')) {
        errorMessage = 'Camera and microphone permissions required for video calls';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Please check app settings';
      }
      AppToast.showError(context, errorMessage);
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

  Widget _buildHighlightedText(String text, String query) {
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
              color: onSurface,
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
            color: onSurface,
            fontWeight: FontWeight.w500,
          ),
        ));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: theme.textTheme.titleMedium?.copyWith(
          color: primary,
          fontWeight: FontWeight.w600,
          backgroundColor: primary.withValues(alpha: 0.2),
        ),
      ));

      start = index + query.length;
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    final allContacts = Contacts.sharedInstance.allContacts.values.toList();
    final filteredContacts = _filterContacts(allContacts);
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
            Expanded(
              child: !hasContacts
                  ? _buildEmptyContactsState(context)
                  : !hasSearchResults && _searchQuery.isNotEmpty
                      ? _buildNoSearchResultsState(context)
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

  Widget _buildSearchBar() {
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
              color: onSurfaceVariant.withValues(alpha: 0.2),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: onSurfaceVariant.withValues(alpha: 0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: onSurfaceVariant.withValues(alpha: 0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
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
    return ValueListenableBuilder<UserDBISAR>(
      valueListenable: ChatCore.Account.sharedInstance.getUserNotifier(contact.pubKey),
      builder: (context, updatedUser, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Use global router for user detail page
              AppRouter.router.push(
                '/user-detail',
                extra: {'pubkey': contact.pubKey},
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildUserAvatar(updatedUser),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildContactName(updatedUser),
                        const SizedBox(height: 4),
                        _buildContactSubtitle(updatedUser),
                      ],
                    ),
                  ),
                  _buildRightSideContent(updatedUser),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserAvatar(UserDBISAR user) {
    return UserAvatar(
      user: user,
      size: 48,
    );
  }

  Widget _buildContactName(UserDBISAR user) {
    if (_searchQuery.isNotEmpty) {
      final nickName = (user.nickName ?? '').trim();
      final name = (user.name ?? '').trim();
      final isNameMatched = _isNameMatched(user);
      final query = _searchQuery.toLowerCase();
      final nickNameLower = nickName.toLowerCase();
      final isNickNameMatched = nickNameLower.contains(query);
      
      if (isNameMatched && nickName.isNotEmpty && name.isNotEmpty) {
        return _buildHighlightedTextWithRemark(nickName, name);
      } else if (isNickNameMatched && nickName.isNotEmpty) {
        return _buildHighlightedText(nickName, _searchQuery);
      } else if (name.isNotEmpty) {
        return _buildHighlightedText(name, _searchQuery);
      } else {
        return Text(
          user.shortEncodedPubkey,
          style: theme.textTheme.titleMedium?.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w500,
          ),
        );
      }
    }
    
    final displayText = _getDisplayNameWithRemark(user);
    return Text(
      displayText,
      style: theme.textTheme.titleMedium?.copyWith(
        color: onSurface,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildHighlightedTextWithRemark(String nickName, String name) {
    final query = _searchQuery.toLowerCase();
    final nameLower = name.toLowerCase();
    
    if (nameLower.contains(query)) {
      final spans = <TextSpan>[];
      
      spans.add(TextSpan(
        text: '$nickName(',
        style: theme.textTheme.titleMedium?.copyWith(
          color: onSurface,
          fontWeight: FontWeight.w500,
        ),
      ));
      
      final nameSpans = _buildHighlightedSpans(name, query);
      spans.addAll(nameSpans);
      
      spans.add(TextSpan(
        text: ')',
        style: theme.textTheme.titleMedium?.copyWith(
          color: onSurface,
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
          color: onSurface,
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }

  List<TextSpan> _buildHighlightedSpans(String text, String query) {
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
              color: onSurface,
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
            color: onSurface,
            fontWeight: FontWeight.w500,
          ),
        ));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: theme.textTheme.titleMedium?.copyWith(
          color: primary,
          fontWeight: FontWeight.w600,
          backgroundColor: primary.withValues(alpha: 0.2),
        ),
      ));

      start = index + query.length;
    }

    return spans;
  }

  Widget _buildContactSubtitle(UserDBISAR user) {
    return Text(
      user.shortEncodedPubkey,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: onSurfaceVariant,
        fontSize: 14,
      ),
    );
  }

  Widget _buildRightSideContent(UserDBISAR user) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildVoiceCallButton(context, user),
        const SizedBox(width: 8),
        _buildVideoCallButton(context, user),
      ],
    );
  }

  Widget _buildVoiceCallButton(BuildContext context, UserDBISAR user) {
    return GestureDetector(
      onTap: () => _startVoiceCall(user.pubKey, user.displayName()),
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          Icons.call,
          size: 24,
          color: primary,
        ),
      ),
    );
  }

  Widget _buildVideoCallButton(BuildContext context, UserDBISAR user) {
    return GestureDetector(
      onTap: () => _startVideoCall(user.pubKey, user.displayName()),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          Icons.videocam,
          size: 24,
          color: primary,
        ),
      ),
    );
  }
}