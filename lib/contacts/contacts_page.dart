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
      AppToast.showInfo(context, 'Call already in progress');
      return;
    }

    setState(() {
      _callingStates[peerId] = true;
    });

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
    } finally {
      setState(() {
        _callingStates[peerId] = false;
      });
    }
  }

  Future<void> _startVideoCall(String peerId, String displayName) async {
    if (_callingStates[peerId] == true) {
      AppToast.showInfo(context, 'Call already in progress');
      return;
    }

    setState(() {
      _callingStates[peerId] = true;
    });

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
    } finally {
      setState(() {
        _callingStates[peerId] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Contacts.sharedInstance.allContacts.isEmpty
          ? _buildEmptyContactsState(context)
          : _buildContactsList(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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

  Widget _buildEmptyContactsState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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

  Widget _buildContactsList(BuildContext context) {
    return ListView.builder(
      itemCount: Contacts.sharedInstance.allContacts.length,
      itemBuilder: (context, index) {
        final contact = Contacts.sharedInstance.allContacts.values.elementAt(index);
        return _buildContactCard(context, contact);
      },
    );
  }

  Widget _buildContactCard(BuildContext context, dynamic contact) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayName = contact.displayName();

    return ListTile(
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
      trailing: _buildCallButtons(context, contact, displayName),
      onTap: () {
        context.push(
          '/user-detail',
          extra: contact.pubKey,
        );
      },
    );
  }

  Widget _buildCallButtons(BuildContext context, dynamic contact, String displayName) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildVoiceCallButton(context, contact, displayName),
        _buildVideoCallButton(context, contact, displayName),
      ],
    );
  }

  Widget _buildVoiceCallButton(BuildContext context, dynamic contact, String displayName) {
    final colorScheme = Theme.of(context).colorScheme;
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

  Widget _buildVideoCallButton(BuildContext context, dynamic contact, String displayName) {
    final colorScheme = Theme.of(context).colorScheme;
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
