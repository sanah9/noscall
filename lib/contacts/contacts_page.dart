import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/call/contacts/contacts.dart';
import '../call/call_manager.dart';
import '../call/constant/call_type.dart';
import '../utils/toast.dart';
import 'user_avatar.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final CallKitManager _callKitManager = CallKitManager();
  final Map<String, bool> _callingStates = {};

  @override
  void initState() {
    super.initState();
    // Register callback to update UI when contacts change
    Contacts.sharedInstance.contactUpdatedCallBack = () {
      if (mounted) {
        setState(() {});
      }
    };
  }

  Future<void> _startVoiceCall(String peerId, String displayName) async {
    if (_callingStates[peerId] == true) {
      AppToast.showInfo('Call already in progress');
      return;
    }

    setState(() {
      _callingStates[peerId] = true;
    });

    try {
      AppToast.showInfo('Starting voice call...');

      final controller = await _callKitManager.startCall(
        peerId: peerId,
        callType: CallingType.audio,
      );

      if (controller == null) {
        AppToast.showError('Failed to start voice call');
      } else {
        AppToast.showSuccess('Voice call started');
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
      AppToast.showError(errorMessage);
    } finally {
      setState(() {
        _callingStates[peerId] = false;
      });
    }
  }

  Future<void> _startVideoCall(String peerId, String displayName) async {
    if (_callingStates[peerId] == true) {
      AppToast.showInfo('Call already in progress');
      return;
    }

    setState(() {
      _callingStates[peerId] = true;
    });

    try {
      AppToast.showInfo('Starting video call...');

      final controller = await _callKitManager.startCall(
        peerId: peerId,
        callType: CallingType.video,
      );

      if (controller == null) {
        AppToast.showError('Failed to start video call');
      } else {
        AppToast.showSuccess('Video call started');
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
      AppToast.showError(errorMessage);
    } finally {
      setState(() {
        _callingStates[peerId] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: _buildAppBar(context, colorScheme),
      body: Contacts.sharedInstance.allContacts.isEmpty
          ? _buildEmptyContactsState(theme, colorScheme)
          : _buildContactsList(context, theme, colorScheme),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ColorScheme colorScheme) {
    return AppBar(
      title: const Text('Contacts'),
      centerTitle: true,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: () {
            context.push('/add-contact');
          },
          icon: const Icon(Icons.person_add),
          tooltip: 'Add Contact',
        ),
      ],
    );
  }

  Widget _buildEmptyContactsState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Contacts',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add contacts to start calling',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return ListView.builder(
      itemCount: Contacts.sharedInstance.allContacts.length,
      itemBuilder: (context, index) {
        final contact = Contacts.sharedInstance.allContacts.values.elementAt(index);
        return _buildContactCard(context, contact, theme, colorScheme);
      },
    );
  }

  Widget _buildContactCard(BuildContext context, dynamic contact, ThemeData theme, ColorScheme colorScheme) {
    final displayName = contact.getUserShowName();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      child: ListTile(
        leading: UserAvatar(user: contact),
        title: Text(
          displayName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          contact.shortEncodedPubkey,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: _buildCallButtons(contact, displayName, colorScheme),
        onTap: () {
          context.push(
            '/user-detail',
            extra: contact.pubKey,
          );
        },
      ),
    );
  }

  Widget _buildCallButtons(dynamic contact, String displayName, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildVoiceCallButton(contact, displayName, colorScheme),
        _buildVideoCallButton(contact, displayName, colorScheme),
      ],
    );
  }

  Widget _buildVoiceCallButton(dynamic contact, String displayName, ColorScheme colorScheme) {
    final isCalling = _callingStates[contact.pubKey] == true;
    
    return IconButton(
      onPressed: isCalling ? null : () => _startVoiceCall(contact.pubKey, displayName),
      icon: isCalling
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.primary,
                ),
              ),
            )
          : Icon(Icons.call, color: colorScheme.primary),
      tooltip: 'Voice Call',
    );
  }

  Widget _buildVideoCallButton(dynamic contact, String displayName, ColorScheme colorScheme) {
    final isCalling = _callingStates[contact.pubKey] == true;
    
    return IconButton(
      onPressed: isCalling ? null : () => _startVideoCall(contact.pubKey, displayName),
      icon: isCalling
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.secondary,
                ),
              ),
            )
          : Icon(Icons.videocam, color: colorScheme.secondary),
      tooltip: 'Video Call',
    );
  }
}
