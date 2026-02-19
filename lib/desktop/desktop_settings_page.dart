import 'package:flutter/material.dart' hide AboutDialog;
import 'package:go_router/go_router.dart';
import 'package:noscall/contacts/user_avatar.dart';
import 'package:noscall/utils/toast.dart';
import 'package:noscall/auth/auth_service.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import 'package:noscall/setting/widgets/keys_dialog.dart';
import 'package:noscall/setting/widgets/about_dialog.dart' as app_about;
import 'package:noscall/setting/widgets/theme_dialog.dart';
import 'desktop_page_wrapper.dart';
import 'desktop_navigator.dart';

class DesktopSettingsPage extends StatefulWidget {
  const DesktopSettingsPage({super.key});

  @override
  State<DesktopSettingsPage> createState() => _DesktopSettingsPageState();
}

class _DesktopSettingsPageState extends State<DesktopSettingsPage> {
  final AuthService _authService = AuthService();
  ValueNotifier<UserDBISAR>? userNotifier;
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
      if (user != null) {
        userNotifier = Account.sharedInstance.getUserNotifier(user.pubKey);
      }
    } catch (e) {
      AppToast.showError(context, 'Failed to load user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (mounted) {
        AppToast.showSuccess(context, 'Logged out successfully');
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Logout failed: $e');
      }
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
            'Are you sure you want to logout?',
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

    if (userNotifier == null) {
      return _buildErrorState(context);
    }

    return _buildContent(context);
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DesktopPageWrapper(
      title: 'Profile',
      child: Center(
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

    return DesktopPageWrapper(
      title: 'Profile',
      child: Center(
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

  Widget _buildContent(BuildContext context) {
    return DesktopPageWrapper(
      title: 'Profile',
      child: ValueListenableBuilder(
        valueListenable: userNotifier!,
        builder: (context, user, _) {
          return ListView(
            padding: const EdgeInsets.all(32),
            children: [
              _buildProfileCard(context, user),
              const SizedBox(height: 24),
              _buildSettingsSection(context, user),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, UserDBISAR user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withValues(alpha: 0.8),
              colorScheme.tertiary.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: UserAvatar(
                        user: user,
                        size: 100,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.displayName(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  final navigatorState = DesktopNavigatorProvider.of(context);
                  navigatorState?.navigateToProfileSettings();
                },
                tooltip: 'Edit Profile',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, UserDBISAR user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildSettingItem(
                context: context,
                icon: Icons.key,
                title: 'Keys',
                onTap: () => KeysDialog.show(context),
              ),
              _buildDivider(colorScheme),
              _buildSettingItem(
                context: context,
                icon: Icons.cloud_outlined,
                title: 'Relays',
                onTap: () => context.push('/relay-management'),
              ),
              _buildDivider(colorScheme),
              _buildSettingItem(
                context: context,
                icon: Icons.settings_ethernet,
                title: 'ICE Servers',
                onTap: () => context.push('/ice-server-management'),
              ),
              _buildDivider(colorScheme),
              _buildSettingItem(
                context: context,
                icon: Icons.palette,
                title: 'Theme',
                onTap: () => ThemeDialog.show(context),
              ),
              _buildDivider(colorScheme),
              _buildSettingItem(
                context: context,
                icon: Icons.info_outline,
                title: 'About',
                onTap: () => app_about.AboutDialog.show(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          clipBehavior: Clip.antiAlias,
          child: _buildSettingItem(
            context: context,
            icon: Icons.logout,
            title: 'Logout',
            onTap: _showLogoutDialog,
            textColor: colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveTextColor = textColor ?? colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: textColor != null
                    ? colorScheme.error.withValues(alpha: 0.1)
                    : colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: effectiveTextColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: effectiveTextColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Divider(
        height: 1,
        thickness: 1,
        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
      ),
    );
  }
}