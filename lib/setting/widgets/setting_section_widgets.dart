import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:noscall/contacts/user_avatar.dart';
import 'package:noscall/core/account/model/user_db_isar.dart';

/// One menu item for the settings list (icon, title, onTap, optional error color).
class SettingMenuItem {
  const SettingMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
}

/// Profile header section: gradient background, avatar, name, QR and Edit buttons.
class SettingProfileHeader extends StatelessWidget {
  const SettingProfileHeader({
    super.key,
    required this.userNotifier,
    required this.theme,
    required this.primary,
    required this.onPrimary,
    required this.onShowQrCode,
    required this.onEditProfile,
  });

  final ValueListenable<UserDBISAR> userNotifier;
  final ThemeData theme;
  final Color primary;
  final Color onPrimary;
  final VoidCallback onShowQrCode;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    const actionMargin = 8.0;
    return ValueListenableBuilder<UserDBISAR>(
      valueListenable: userNotifier,
      builder: (context, user, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomLeft,
              colors: [
                primary,
                primary.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24.0,
                    horizontal: 40.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildProfileAvatar(user),
                      const SizedBox(height: 16),
                      _buildProfileInfo(user),
                    ],
                  ),
                ),
                Positioned(
                  top: actionMargin,
                  left: actionMargin,
                  child: IconButton(
                    icon: Icon(Icons.qr_code, color: onPrimary),
                    onPressed: onShowQrCode,
                    tooltip: 'Show QR Code',
                  ),
                ),
                Positioned(
                  top: actionMargin,
                  right: actionMargin,
                  child: IconButton(
                    icon: Icon(Icons.edit, color: onPrimary),
                    onPressed: onEditProfile,
                    tooltip: 'Edit Profile',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(UserDBISAR user) {
    return Container(
      width: 126,
      height: 126,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: UserAvatar(user: user, size: 126),
    );
  }

  Widget _buildProfileInfo(UserDBISAR user) {
    return Column(
      children: [
        Text(
          user.displayName(),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: onPrimary,
          ),
        ),
      ],
    );
  }
}

/// Network status label from connectivity result.
String networkStatusLabel(List<ConnectivityResult> connectivity) {
  if (connectivity.isEmpty) return 'Unknown';
  final status = connectivity.first;
  if (status == ConnectivityResult.wifi) return 'WiFi';
  if (status == ConnectivityResult.mobile) return 'Mobile';
  if (status == ConnectivityResult.ethernet) return 'Ethernet';
  if (status == ConnectivityResult.vpn) return 'VPN';
  if (status == ConnectivityResult.none) return 'No connection';
  if (status == ConnectivityResult.bluetooth) return 'Bluetooth';
  return 'Other';
}

/// Menu section: network tile + list of setting menu items.
class SettingMenuSection extends StatelessWidget {
  const SettingMenuSection({
    super.key,
    required this.connectivity,
    required this.menuItems,
  });

  final List<ConnectivityResult> connectivity;
  final List<SettingMenuItem> menuItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isConnected = connectivity.isNotEmpty &&
        connectivity.first != ConnectivityResult.none;

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: menuItems.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return ListTile(
            leading: Icon(
              isConnected ? Icons.wifi : Icons.wifi_off,
              color: isConnected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            title: Text(
              'Network',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Text(
              networkStatusLabel(connectivity),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        final item = menuItems[index - 1];
        return SettingMenuTile(
          icon: item.icon,
          title: item.title,
          onTap: item.onTap,
          textColor: item.textColor,
        );
      },
    );
  }
}

/// One row in the settings menu list (icon, title, chevron).
class SettingMenuTile extends StatelessWidget {
  const SettingMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? colorScheme.primary,
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: textColor ?? colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
