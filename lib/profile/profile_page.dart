import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:noscall/contacts/user_avatar.dart';
import '../utils/toast.dart';
import '../auth/auth_service.dart';
import '../core/account/account.dart';
import '../core/account/model/userDB_isar.dart';
import '../core/account/relays.dart';
import 'package:nostr/nostr.dart';

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
  });
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  UserDBISAR? _user;
  bool _isLoading = true;
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = packageInfo;
    });
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = Account.sharedInstance.me;
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppToast.showError(context, 'Failed to load user data: $e');
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      AppToast.showSuccess(context, 'Logged out successfully');
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      AppToast.showError(context, 'Logout failed: $e');
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          title: Text(
            'Logout',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to logout? You will need to enter your private key again to sign back in.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                await _logout();
              },
              child: Text(
                'Logout',
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState(context);
    }

    if (_user == null) {
      return _buildErrorState(context);
    }

    return _buildProfileContent(context);
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading profile...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No user data found',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please log in again',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _logout,
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildProfileHeader(context),
          _buildMenuSection(context),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 24.0,
        horizontal: 40.0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomLeft,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildProfileAvatar(context),
            const SizedBox(height: 16),
            _buildProfileInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    return UserAvatar(
      user: _user!,
      radius: 60,
    );
  }

  Widget _buildProfileInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Text(
          _user?.displayName() ?? '',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            final value = _user?.encodedPubkey ?? '';
            if (value.isNotEmpty) {
              Clipboard.setData(ClipboardData(text: value));
              AppToast.showSuccess(context, 'pubkey copied to clipboard');
            }
          },
          child: Text(
            _user?.encodedPubkey ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final menuItems = [
      _MenuItem(
        icon: Icons.key,
        title: 'Keys',
        onTap: () => _showKeysDialog(context),
      ),
      _MenuItem(
        icon: Icons.cloud_circle,
        title: 'Relays',
        onTap: () => _showRelaysDialog(context),
      ),
      _MenuItem(
        icon: Icons.info_outline,
        title: 'About',
        onTap: () => _showAboutDialog(context),
      ),
      _MenuItem(
        icon: Icons.logout,
        title: 'Logout',
        onTap: _showLogoutDialog,
        textColor: colorScheme.error,
      ),
    ];

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return _buildMenuTile(
          context: context,
          icon: item.icon,
          title: item.title,
          onTap: item.onTap,
          textColor: item.textColor,
        );
      },
    );
  }

  void _showKeysDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _buildKeysDialog(context),
    );
  }

  Widget _buildKeysDialog(BuildContext context) {
    final account = Account.sharedInstance;
    
    // Convert pubkey to npub format
    final npub = Nip19.encodePubkey(account.currentPubkey);
    final nsec = Nip19.encodePrivkey(account.currentPrivkey);

    return AlertDialog(
      title: const Text('Your Keys'),
      content: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSimpleKeyItem(
              context: context,
              title: 'Public Key',
              value: npub,
              isPrivate: false,
            ),
            Container(
              height: 1,
              color: Colors.grey.shade300,
              margin: const EdgeInsets.symmetric(vertical: 16),
            ),
            _buildSimpleKeyItem(
              context: context,
              title: 'Private Key',
              value: nsec.isEmpty ? 'login with signer' : nsec,
              isPrivate: nsec.isNotEmpty,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildSimpleKeyItem({
    required BuildContext context,
    required String title,
    required String value,
    required bool isPrivate,
  }) {
    final theme = Theme.of(context);
    final displayValue = isPrivate ? '•' * value.length : value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                displayValue,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: isPrivate ? null : 'monospace',
                  color: Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                AppToast.showInfo(context, '$title copied to clipboard');
              },
              child: Icon(
                Icons.copy,
                color: Colors.grey.shade600,
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showRelaysDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _buildRelaysDialog(context),
    );
  }

  Widget _buildRelaysDialog(BuildContext context) {
    final theme = Theme.of(context);
    final relays = Relays.sharedInstance.recommendGeneralRelays;

    return AlertDialog(
      title: const Text('App Relays'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: relays.length,
          itemBuilder: (context, index) {
            final relay = relays[index];
            return ListTile(
              title: Text(
                relay,
                style: theme.textTheme.bodyMedium,
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _buildAboutDialog(context),
    );
  }

  Widget _buildAboutDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('About Noscall'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_packageInfo != null) ...[
            Text('Version: ${_packageInfo!.version}'),
            Text('Build: ${_packageInfo!.buildNumber}'),
            Text('Package: ${_packageInfo!.packageName}'),
            const Text('GitHub: https://github.com/noscall/noscall'),
            const Text('Description: A secure voice and video calling app built on Nostr'),
            const SizedBox(height: 8),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
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
