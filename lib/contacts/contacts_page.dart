import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
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

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Contacts.sharedInstance.allContacts.isEmpty
          ? _buildEmptyContactsState(context)
          : _buildContactsList(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Contacts'),
      centerTitle: true,
      backgroundColor: surface,
      foregroundColor: onSurface,
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

  Widget _buildContactsList(BuildContext context) {
    return ListView.builder(
      itemCount: Contacts.sharedInstance.allContacts.length,
      itemBuilder: (context, index) {
        final contact = Contacts.sharedInstance.allContacts.values.elementAt(index);
        return _buildContactCard(context, contact);
      },
    );
  }

  Widget _buildContactCard(BuildContext context, UserDBISAR contact) {
    final displayName = contact.displayName();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push(
            '/user-detail',
            extra: {'pubkey': contact.pubKey},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildUserAvatar(contact),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContactName(contact, displayName),
                    const SizedBox(height: 4),
                    _buildContactSubtitle(contact),
                  ],
                ),
              ),
              _buildRightSideContent(contact, displayName),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(UserDBISAR contact) {
    return UserAvatar(
      user: contact,
      radius: 24,
    );
  }

  Widget _buildContactName(UserDBISAR contact, String displayName) {
    return Text(
      displayName,
      style: theme.textTheme.titleMedium?.copyWith(
        color: onSurface,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildContactSubtitle(UserDBISAR contact) {
    return Text(
      contact.shortEncodedPubkey,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: onSurfaceVariant,
        fontSize: 14,
      ),
    );
  }

  Widget _buildRightSideContent(UserDBISAR contact, String displayName) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildVoiceCallButton(context, contact, displayName),
        const SizedBox(width: 8),
        _buildVideoCallButton(context, contact, displayName),
      ],
    );
  }

  Widget _buildVoiceCallButton(BuildContext context, UserDBISAR contact, String displayName) {
    return GestureDetector(
      onTap: () => _startVoiceCall(contact.pubKey, displayName),
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

  Widget _buildVideoCallButton(BuildContext context, UserDBISAR contact, String displayName) {
    return GestureDetector(
      onTap: () => _startVideoCall(contact.pubKey, displayName),
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
