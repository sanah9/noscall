import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/contacts/user_avatar.dart';
import '../utils/toast.dart';
import '../auth/auth_service.dart';
import '../core/account/account.dart';
import '../core/account/model/userDB_isar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  UserDBISAR? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
      AppToast.showError('Failed to load user data: $e');
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      AppToast.showSuccess('Logged out successfully');
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      AppToast.showError('Logout failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return _buildLoadingState(theme, colorScheme);
    }

    if (_user == null) {
      return _buildErrorState(theme, colorScheme);
    }

    return _buildProfileContent(context, theme, colorScheme);
  }

  Widget _buildLoadingState(ThemeData theme, ColorScheme colorScheme) {
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

  Widget _buildErrorState(ThemeData theme, ColorScheme colorScheme) {
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

  Widget _buildProfileContent(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(context, theme, colorScheme),
            _buildMenuSection(context, theme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildProfileAvatar(theme, colorScheme),
            const SizedBox(height: 16),
            _buildProfileInfo(theme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(ThemeData theme, ColorScheme colorScheme) {
    return UserAvatar(
      user: _user!,
      radius: 60,
    );
  }

  Widget _buildProfileInfo(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          _user!.displayName(),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _user!.shortEncodedPubkey,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onPrimary.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        if (_user!.about != null && _user!.about!.isNotEmpty) ...[
          Text(
            _user!.about!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
        ],
        _buildOnlineStatus(theme, colorScheme),
      ],
    );
  }

  Widget _buildOnlineStatus(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.tertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Online',
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onTertiary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildMenuTile(
            context: context,
            icon: Icons.person_outline,
            title: 'Account Info',
            subtitle: 'View account details',
            onTap: () {
              context.push('/account-info');
            },
          ),
          const Divider(),
          _buildMenuTile(
            context: context,
            icon: Icons.settings,
            title: 'Settings',
            subtitle: 'App preferences',
            onTap: () {
              AppToast.showInfo('Settings feature coming soon');
            },
          ),
          const Divider(),
          _buildMenuTile(
            context: context,
            icon: Icons.security,
            title: 'Privacy & Security',
            subtitle: 'Manage your privacy',
            onTap: () {
              AppToast.showInfo('Privacy settings coming soon');
            },
          ),
          const Divider(),
          _buildMenuTile(
            context: context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help and support',
            onTap: () {
              AppToast.showInfo('Help center coming soon');
            },
          ),
          const Divider(),
          _buildMenuTile(
            context: context,
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App version and info',
            onTap: () => _showAboutDialog(context),
          ),
          const Divider(),
          _buildMenuTile(
            context: context,
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            onTap: _logout,
            textColor: colorScheme.error,
          ),
        ],
      ),
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
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Version: 1.0.0'),
          Text('Build: 2024.01.15'),
          SizedBox(height: 8),
          Text('A secure voice calling app built with Flutter and Nostr protocol.'),
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
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      elevation: 0,
      child: ListTile(
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
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor?.withOpacity(0.7) ?? colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}
