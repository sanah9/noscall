import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/contacts/user_avatar.dart';
import 'package:noscall/core/call/contacts/contacts.dart';
import 'package:noscall/core/call/contacts/contacts+blocklist.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/account/account+profile.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import 'package:noscall/call/call_manager.dart';
import 'package:noscall/call/constant/call_type.dart';
import 'package:noscall/call_history/constants/call_enums.dart';
import 'package:noscall/call_history/models/call_entry.dart';
import '../utils/toast.dart';

class UserDetailPage extends StatefulWidget {
  final String pubkey;
  final List<CallEntry>? callHistory;

  const UserDetailPage({
    super.key,
    required this.pubkey,
    this.callHistory,
  });

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  late ValueNotifier<UserDBISAR> user;
  late ValueNotifier<bool> isContact;
  late ValueNotifier<bool> isBlocked;
  late ValueNotifier<bool> isLoading;
  late ValueNotifier<bool> isUpdatingFromRemote;

  late ThemeData theme;
  BorderRadius get sectionRadius => BorderRadius.circular(16);
  Color get primary => theme.colorScheme.primary;
  Color get primaryContainer => theme.colorScheme.primaryContainer.withValues(alpha: 0.3);
  Color get surface => theme.colorScheme.surface;
  Color get onSurface => theme.colorScheme.onSurface;
  Color get onSurfaceVariant => theme.colorScheme.onSurfaceVariant;
  Color get borderColor => theme.colorScheme.outline.withValues(alpha: 0.1);

  @override
  void initState() {
    super.initState();
    _initializeData();
    _updateUserInfoFromRemote();
  }

  void _initializeData() {
    user = Account.sharedInstance.getUserNotifier(widget.pubkey);
    isContact = ValueNotifier(Contacts.sharedInstance.allContacts.containsKey(widget.pubkey));
    isBlocked = ValueNotifier(Contacts.sharedInstance.inBlockList(widget.pubkey));
    isLoading = ValueNotifier(false);
    isUpdatingFromRemote = ValueNotifier(false);
  }

  @override
  void dispose() {
    isContact.dispose();
    isBlocked.dispose();
    isLoading.dispose();
    isUpdatingFromRemote.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    return ValueListenableBuilder<UserDBISAR>(
      valueListenable: user,
      builder: (context, userData, child) {
        return _buildMainView(userData);
      },
    );
  }

  Widget _buildMainView(UserDBISAR userData) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: ListView(
        children: [
          const SizedBox(height: 12),
          _buildUserProfileSection(userData),
          _buildActionButtons(),
          _buildCallHistorySection(),
          _buildUserInfoSection(userData),
          _buildContactManagementSection(),
          _buildBlockManagementSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildUserProfileSection(UserDBISAR userData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Stack(
            children: [
              UserAvatar(
                radius: 50,
                user: userData,
              ),
              ValueListenableBuilder<bool>(
                valueListenable: isUpdatingFromRemote,
                builder: (context, isUpdating, child) {
                  if (isUpdating) {
                    return Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: surface,
                          shape: BoxShape.circle,
                        ),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(primary),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getDisplayName(userData),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.call,
            onPressed: _startCall,
          ),
          _buildActionButton(
            icon: Icons.videocam,
            onPressed: _startVideoCall,
          ),
        ],
      ),
    );
  }

  Widget _buildCallHistorySection() {
    if (widget.callHistory == null || widget.callHistory!.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Text(
              'Call History',
              style: theme.textTheme.titleMedium?.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...widget.callHistory!.asMap().entries.map((entry) {
            final index = entry.key;
            final callEntry = entry.value;
            final isLast = index == widget.callHistory!.length - 1;

            return _buildCallHistoryItem(callEntry, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildCallHistoryItem(CallEntry callEntry, bool isLast) {
    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(
            color: borderColor,
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        leading: _buildCircularIcon(
          icon: switch (callEntry.direction) {
            CallDirection.incoming => Icons.call_received,
            CallDirection.outgoing => Icons.call_made,
          },
        ),
        title: Text(
          switch (callEntry.direction) {
            CallDirection.incoming => 'Incoming Call',
            CallDirection.outgoing => 'Outgoing Call',
          },
          style: theme.textTheme.bodyMedium?.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _getCallStatusText(callEntry),
          style: theme.textTheme.bodySmall?.copyWith(
            color: onSurfaceVariant,
          ),
        ),
        trailing: Text(
          _formatCallTime(callEntry.startTime),
          style: theme.textTheme.bodySmall?.copyWith(
            color: onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoSection(UserDBISAR userData) {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserInfoItem(
            icon: Icons.fingerprint,
            title: 'NPUB',
            value: userData.encodedPubkey,
            onTap: () => _copyNpub(userData.encodedPubkey),
            trailingIcon: Icons.copy,
          ),
          _buildUserInfoItem(
            icon: Icons.person,
            title: 'Name',
            value: userData.name ?? '',
            onTap: null,
          ),
          _buildUserInfoItem(
            icon: Icons.label,
            title: 'Nickname',
            value: userData.nickName ?? 'Not set',
            onTap: () => _editNickname(userData),
            trailingIcon: Icons.edit,
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback? onTap,
    IconData? trailingIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: borderColor,
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        // leading: _buildCircularIcon(icon: icon),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: onSurfaceVariant,
          ),
        ),
        trailing: trailingIcon != null
            ? Icon(
          trailingIcon,
          color: primary,
          size: 16,
        )
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildContactManagementSection() {
    return ValueListenableBuilder<bool>(
      valueListenable: isContact,
      builder: (context, isContactValue, child) {
        return _buildSectionContainer(
          child: ValueListenableBuilder<bool>(
            valueListenable: isLoading,
            builder: (context, isLoadingValue, child) {
              final title = isContactValue ? 'Remove from Contacts' : 'Add to Contacts';
              final icon = isContactValue ? Icons.person_remove : Icons.person_add;
              final onTap = isContactValue ? _removeContact : _addContact;

              return Column(
                children: [
                  _buildSectionTile(
                    title: title,
                    icon: icon,
                    onTap: onTap,
                    isLoading: isLoadingValue,
                    textColor: isContactValue ? theme.colorScheme.error : null,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBlockManagementSection() {
    return _buildSectionContainer(
      child: ValueListenableBuilder<bool>(
        valueListenable: isBlocked,
        builder: (context, isBlockedValue, child) {
          return ValueListenableBuilder<bool>(
            valueListenable: isLoading,
            builder: (context, isLoadingValue, child) {
              final title = isBlockedValue ? 'Unblock Contact' : 'Block Contact';
              return _buildSectionTile(
                title: title,
                icon: Icons.block,
                onTap: _toggleBlock,
                isLoading: isLoadingValue,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: _buildBlurBackgroundDecoration(),
      child: ClipRRect(
        borderRadius: sectionRadius,
        child: Material(
          color: Colors.transparent,
          child: child,
        ),
      ),
    );
  }

  BoxDecoration _buildBlurBackgroundDecoration() {
    return BoxDecoration(
      color: primaryContainer,
      borderRadius: sectionRadius,
      border: Border.all(
        color: borderColor,
        width: 0.5,
      ),
    );
  }

  Widget _buildCircularIcon({
    required IconData icon,
  }) {
    final color = primary;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }

  Widget _buildSectionTile({
    required String title,
    required IconData icon,
    required VoidCallback? onTap,
    bool isLoading = false,
    Color? textColor,
  }) {
    return ListTile(
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: textColor ?? primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: isLoading ? null : onTap,
    );
  }

  Future<void> _handleAsyncOperation({
    required Future<void> Function() operation,
    required String successMessage,
    required String errorMessage,
  }) async {
    isLoading.value = true;
    try {
      await operation();
      AppToast.showSuccess(context, successMessage);
    } catch (e) {
      AppToast.showError(context, '$errorMessage: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 60,
          height: 60,
          decoration: _buildBlurBackgroundDecoration(),
          child: Icon(
            icon,
            color: primary,
            size: 28,
          ),
        ),
      ),
    );
  }

  String _getDisplayName(UserDBISAR userData) {
    if (userData.nickName != null && userData.nickName!.isNotEmpty) {
      return userData.nickName!;
    } else if (userData.name != null && userData.name!.isNotEmpty) {
      return userData.name!;
    } else {
      return userData.shortEncodedPubkey;
    }
  }

  void _copyNpub(String npub) {
    if (npub.isEmpty) {
      AppToast.showError(context, 'NPUB not available');
      return;
    }

    Clipboard.setData(ClipboardData(text: npub));
    AppToast.showSuccess(context, 'NPUB copied to clipboard');
  }

  void _editNickname(UserDBISAR userData) {
    context.push('/edit-nickname', extra: {
      'pubkey': widget.pubkey,
      'currentNickname': userData.nickName ?? '',
    });
  }

  String _formatCallTime(DateTime startTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final startDate = DateTime(startTime.year, startTime.month, startTime.day);

    if (startDate == today) {
      return 'Today・${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    } else if (startDate == yesterday) {
      return 'Yesterday・${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    } else {
      final difference = today.difference(startDate).inDays;
      if (difference < 7) {
        return '${difference} days ago・${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      } else {
        return '${startTime.month}/${startTime.day}・${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      }
    }
  }

  String _getCallStatusText(CallEntry callEntry) {
    return switch (callEntry.status) {
      CallStatus.declined => 'Declined',
      CallStatus.failed => 'Failed',
      CallStatus.cancelled => 'Cancelled',
      CallStatus.completed => _formatCallDuration(callEntry.duration),
    };
  }

  String _formatCallDuration(Duration? duration) {
    if (duration == null) return '0s';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  void _addContact() async {
    await _handleAsyncOperation(
      operation: () async {
        final result = await Contacts.sharedInstance.addToContact([widget.pubkey]);
        if (result.status) {
          isContact.value = true;
        } else {
          throw Exception('Failed to add contact');
        }
      },
      successMessage: 'Contact added',
      errorMessage: 'Failed to add contact',
    );
  }

  void _removeContact() async {
    final confirmed = await _showRemoveContactConfirmation();
    if (!confirmed) return;

    await _handleAsyncOperation(
      operation: () async {
        final result = await Contacts.sharedInstance.removeContact(widget.pubkey);
        if (result.status) {
          isContact.value = false;
        } else {
          throw Exception('Failed to remove contact');
        }
      },
      successMessage: 'Contact removed',
      errorMessage: 'Failed to remove contact',
    );
  }

  Future<bool> _showRemoveContactConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Contact'),
        content: const Text('Are you sure you want to remove this contact from your contacts list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _toggleBlock() async {
    await _handleAsyncOperation(
      operation: () async {
        if (isBlocked.value) {
          final result = await Contacts.sharedInstance.removeBlockList([widget.pubkey]);
          if (result.status) {
            isBlocked.value = false;
          } else {
            throw Exception('Failed to unblock contact');
          }
        } else {
          final result = await Contacts.sharedInstance.addToBlockList(widget.pubkey);
          if (result.status) {
            isBlocked.value = true;
          } else {
            throw Exception('Failed to block contact');
          }
        }
      },
      successMessage: isBlocked.value ? 'Contact unblocked' : 'Contact blocked',
      errorMessage: 'Operation failed',
    );
  }

  void _startCall() async {
    if (isBlocked.value) {
      AppToast.showError(context, 'Cannot call blocked user');
      return;
    }

    try {
      await CallKitManager().startCall(
        peerId: widget.pubkey,
        callType: CallType.audio,
      );
    } catch (e) {
      AppToast.showError(context, 'Failed to start call: $e');
    }
  }

  void _startVideoCall() async {
    if (isBlocked.value) {
      AppToast.showError(context, 'Cannot call blocked user');
      return;
    }

    try {
      await CallKitManager().startCall(
        peerId: widget.pubkey,
        callType: CallType.video,
      );
    } catch (e) {
      AppToast.showError(context, 'Failed to start video call: $e');
    }
  }

  Future<void> _updateUserInfoFromRemote() async {
    if (isUpdatingFromRemote.value) return; // Prevent multiple simultaneous updates

    isUpdatingFromRemote.value = true;
    try {
      await Account.sharedInstance.reloadProfileFromRelay(widget.pubkey);
      // The user notifier will automatically update the UI when the data changes
    } finally {
      isUpdatingFromRemote.value = false;
    }
  }
}