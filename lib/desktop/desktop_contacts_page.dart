import 'package:flutter/material.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import '../core/call/contacts/contacts.dart';
import '../call/call_manager.dart';
import '../call/constant/call_type.dart';
import '../utils/toast.dart';
import '../contacts/user_avatar.dart';
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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<UserDBISAR> _filterContacts(List<UserDBISAR> contacts) {
    if (_searchQuery.isEmpty) return contacts;

    return contacts.where((contact) {
      final name = (contact.name ?? '').toLowerCase();
      final displayName = contact.displayName().toLowerCase();
      return name.contains(_searchQuery) || displayName.contains(_searchQuery);
    }).toList();
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
    final filteredContacts = _filterContacts(allContacts);

    return DesktopPageWrapper(
      title: 'Contacts',
      trailing: DesktopSearchBar(
        controller: _searchController,
        hintText: 'Search...',
        onChanged: _onSearchChanged,
      ),
      child: filteredContacts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.contacts_outlined,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty ? 'No contacts yet' : 'No results found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
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
              const SizedBox(width: 16),
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