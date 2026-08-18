import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:noscall/call_history/constants/call_enums.dart';
import 'package:noscall/call_history/models/call_entry.dart';
import 'package:noscall/contacts/user_avatar.dart';
import 'package:noscall/core/account/model/user_db_isar.dart';

import '../services/contact_remark_service.dart';

class UserDetailProfileSection extends StatelessWidget {
  const UserDetailProfileSection({
    super.key,
    required this.user,
    required this.theme,
    required this.primary,
    required this.surface,
    required this.onSurface,
    required this.isUpdatingFromRemote,
    required this.displayName,
  });

  final UserDBISAR user;
  final ThemeData theme;
  final Color primary;
  final Color surface;
  final Color onSurface;
  final ValueListenable<bool> isUpdatingFromRemote;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Stack(
            children: [
              UserAvatar(size: 100, user: user),
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
            displayName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class UserDetailActionButtons extends StatelessWidget {
  const UserDetailActionButtons({
    super.key,
    required this.primary,
    required this.sectionRadius,
    required this.borderColor,
    required this.primaryContainer,
    required this.onCall,
    required this.onVideoCall,
    required this.onVoiceMessage,
  });

  final Color primary;
  final BorderRadius sectionRadius;
  final Color borderColor;
  final Color primaryContainer;
  final VoidCallback onCall;
  final VoidCallback onVideoCall;
  final VoidCallback onVoiceMessage;

  BoxDecoration _decoration() => BoxDecoration(
    color: primaryContainer,
    borderRadius: sectionRadius,
    border: Border.all(color: borderColor, width: 0.5),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildButton(icon: Icons.call, onPressed: onCall),
          _buildButton(icon: Icons.videocam, onPressed: onVideoCall),
          _buildButton(icon: Icons.mic_none, onPressed: onVoiceMessage),
        ],
      ),
    );
  }

  Widget _buildButton({
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
          decoration: _decoration(),
          child: Icon(icon, color: primary, size: 28),
        ),
      ),
    );
  }
}

class UserDetailCallHistorySection extends StatelessWidget {
  const UserDetailCallHistorySection({
    super.key,
    required this.callHistory,
    required this.theme,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.borderColor,
    required this.primary,
    required this.sectionRadius,
    required this.primaryContainer,
    required this.formatCallTime,
    required this.getCallStatusText,
    this.onViewPaymentDetails,
  });

  final List<CallEntry> callHistory;
  final ThemeData theme;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color borderColor;
  final Color primary;
  final BorderRadius sectionRadius;
  final Color primaryContainer;
  final String Function(DateTime) formatCallTime;
  final String Function(CallEntry) getCallStatusText;
  final ValueChanged<CallEntry>? onViewPaymentDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: primaryContainer,
        borderRadius: sectionRadius,
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: sectionRadius,
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: Text(
                  'Call History',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...callHistory.asMap().entries.map((entry) {
                final index = entry.key;
                final callEntry = entry.value;
                final isLast = index == callHistory.length - 1;
                return _buildItem(callEntry, isLast);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(CallEntry callEntry, bool isLast) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: ListTile(
        leading: _circleIcon(switch (callEntry.direction) {
          CallDirection.incoming => Icons.call_received,
          CallDirection.outgoing => Icons.call_made,
        }),
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
          getCallStatusText(callEntry),
          style: theme.textTheme.bodySmall?.copyWith(color: onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatCallTime(callEntry.startTime),
              style: theme.textTheme.bodySmall?.copyWith(
                color: onSurfaceVariant,
              ),
            ),
            if (onViewPaymentDetails != null) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: 'Payment details',
                child: IconButton(
                  icon: const Icon(Icons.receipt_long_outlined),
                  color: primary,
                  onPressed: () => onViewPaymentDetails?.call(callEntry),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _circleIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: primary, size: 20),
    );
  }
}

class UserDetailInfoSection extends StatelessWidget {
  const UserDetailInfoSection({
    super.key,
    required this.user,
    required this.theme,
    required this.primary,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.borderColor,
    required this.onCopyNpub,
    required this.onEditNickname,
    required this.onEditRemark,
  });

  final UserDBISAR user;
  final ThemeData theme;
  final Color primary;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color borderColor;
  final void Function(String) onCopyNpub;
  final void Function(UserDBISAR) onEditNickname;
  final void Function(UserDBISAR) onEditRemark;

  @override
  Widget build(BuildContext context) {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoItem(
            title: 'NPUB',
            value: user.encodedPubkey,
            onTap: () => onCopyNpub(user.encodedPubkey),
            trailingIcon: Icons.copy,
          ),
          _buildInfoItem(
            title: 'Name',
            value: user.name ?? '',
            onTap: null,
            trailingIcon: null,
          ),
          _buildInfoItem(
            title: 'Nickname',
            value: user.nickName ?? 'Not set',
            onTap: () => onEditNickname(user),
            trailingIcon: Icons.edit,
          ),
          ValueListenableBuilder<Map<String, String>>(
            valueListenable: ContactRemarkService().remarksNotifier,
            builder: (context, remarks, _) {
              final remark = remarks[user.pubKey] ?? '';
              return _buildInfoItem(
                title: 'Remark',
                value: remark.isEmpty ? 'Not set' : remark,
                onTap: () => onEditRemark(user),
                trailingIcon: Icons.edit,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(color: Colors.transparent, child: child),
      ),
    );
  }

  Widget _buildInfoItem({
    required String title,
    required String value,
    required VoidCallback? onTap,
    required IconData? trailingIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: ListTile(
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(color: onSurfaceVariant),
        ),
        trailing: trailingIcon != null
            ? Icon(trailingIcon, color: primary, size: 16)
            : null,
        onTap: onTap,
      ),
    );
  }
}
