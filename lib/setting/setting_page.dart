import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:noscall/core/navigation/app_navigator_scope.dart';
import 'package:noscall/core/ui/status_bar_style.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:noscall/contacts/user_avatar.dart';
import 'package:noscall/utils/toast.dart';
import 'package:noscall/auth/auth_service.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import 'package:noscall/setting/widgets/setting_section_widgets.dart';
import 'package:nostr_core_dart/nostr.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final AuthService _authService = AuthService();
  ValueNotifier<UserDBISAR>? userNotifier;
  bool _isLoading = true;
  List<ConnectivityResult> _connectivity = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  late ThemeData theme;
  Color get primary => theme.colorScheme.primary;
  Color get onSurface => theme.colorScheme.onSurface;
  Color get onSurfaceVariant => theme.colorScheme.onSurfaceVariant;
  Color get onPrimary => theme.colorScheme.onPrimary;
  Color get errorColor => theme.colorScheme.error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    Connectivity().checkConnectivity().then((r) {
      if (mounted) setState(() => _connectivity = r);
    });
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((r) {
      if (mounted) setState(() => _connectivity = r);
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
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
      if (!mounted) return;
      AppToast.showSuccess(context, 'Logged out successfully');
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
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
    theme = Theme.of(context);

    if (_isLoading) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: StatusBarStyle.forBrightness(theme.brightness),
        child: _buildLoadingState(context),
      );
    }

    if (userNotifier == null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: StatusBarStyle.forBrightness(theme.brightness),
        child: _buildErrorState(context),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: StatusBarStyle.forDarkHeader,
      child: _buildProfileContent(context),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading profile...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No user data found',
              style: theme.textTheme.titleLarge?.copyWith(
                color: onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please log in again',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onSurfaceVariant,
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
    final menuItems = [
      SettingMenuItem(
        icon: Icons.security,
        title: 'Account & Security',
        onTap: () => context.push('/settings/account'),
      ),
      SettingMenuItem(
        icon: Icons.cloud,
        title: 'Connection',
        onTap: () => context.push('/settings/connection'),
      ),
      SettingMenuItem(
        icon: Icons.palette_outlined,
        title: 'Appearance & Notifications',
        onTap: () => context.push('/settings/appearance'),
      ),
      SettingMenuItem(
        icon: Icons.storage,
        title: 'Data',
        onTap: () => context.push('/settings/data'),
      ),
      SettingMenuItem(
        icon: Icons.info_outline,
        title: 'About & Debug',
        onTap: () => context.push('/settings/about'),
      ),
      SettingMenuItem(
        icon: Icons.logout,
        title: 'Logout',
        onTap: _showLogoutDialog,
        textColor: errorColor,
      ),
    ];

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SettingProfileHeader(
            userNotifier: userNotifier!,
            theme: theme,
            primary: primary,
            onPrimary: onPrimary,
            onShowQrCode: () => _showQrCodeDialog(context),
            onEditProfile: () => _navigateToProfileSettings(context),
          ),
          SettingMenuSection(
            connectivity: _connectivity,
            menuItems: menuItems,
          ),
        ],
      ),
    );
  }

  void _navigateToProfileSettings(BuildContext context) {
    AppNavigatorScope.requireOf(context).pushProfileSettings(context);
  }

  void _showQrCodeDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _buildQrCodeDialog(context);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Combine slide from bottom and fade animation
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.15), // Slight slide from below
            end: Offset.zero, // End at center
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildQrCodeDialog(BuildContext context) {
    final theme = Theme.of(context);
    final account = Account.sharedInstance;
    final npub = Nip19.encodePubkey(account.currentPubkey);
    final user = userNotifier?.value;
    final displayName = user?.displayName() ?? '';
    const spacerHeight = 12.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: spacerHeight),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    displayName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Icon(Icons.close, color: primary),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: const CircleBorder(),
                      ),
                    ),
                  )
                ],
              ),
            ),
            // QR Code with embedded icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  QrImageView(
                    data: npub,
                    size: 240,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                    backgroundColor: Colors.white,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.circle,
                      color: primary,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.circle,
                      color: primary,
                    ),
                  ),
                  // Center icon overlay
                  if (user != null)
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: UserAvatar(
                          user: user,
                          size: 58,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: spacerHeight * 2),
            // Copy button
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: npub));
                AppToast.showSuccess(context, 'npub copied to clipboard');
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy npub'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: spacerHeight * 2),
          ],
        ),
      ),
    );
  }
}
