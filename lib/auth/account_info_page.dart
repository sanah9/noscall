import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/core/navigation/app_navigator_scope.dart';
import 'package:noscall/utils/toast.dart';
import 'auth_service.dart';
import 'widgets/account_info_sections.dart';

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key});

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  final AuthService _authService = AuthService();
  Map<String, String> _userInfo = {};

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() {
    setState(() {
      _userInfo = _authService.getUserInfo();
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    AppToast.showSuccess(context, '$label copied to clipboard');
  }

  void _showNpubDetails() {
    showDialog(
      context: context,
      builder: (context) => AccountInfoKeyDetailsDialog(
        title: 'Nostr Public Key (npub)',
        description:
            'This is your Nostr public key in bech32 format. You can share this with others to receive calls.',
        value: _userInfo['npub'] ?? '',
        copyLabel: 'npub',
        onCopy: () => _copyToClipboard(_userInfo['npub'] ?? '', 'npub'),
      ),
    );
  }

  void _showPubkeyDetails() {
    showDialog(
      context: context,
      builder: (context) => AccountInfoKeyDetailsDialog(
        title: 'Raw Public Key',
        description:
            'This is your raw public key in hexadecimal format. This is the internal representation used by the app.',
        value: _userInfo['pubkey'] ?? '',
        copyLabel: 'Public Key',
        onCopy: () => _copyToClipboard(_userInfo['pubkey'] ?? '', 'Public Key'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Info'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppNavigatorScope.requireOf(context).pop(context),
        ),
      ),
      body: ListView(
        children: [
          const AccountInfoStatusHeader(),
          AccountInfoPublicKeySection(
            npub: _userInfo['npub'] ?? 'Loading...',
            pubkey: _userInfo['pubkey'] ?? 'Loading...',
            onShowNpubDetails: _showNpubDetails,
            onCopyNpub: () => _copyToClipboard(_userInfo['npub'] ?? '', 'npub'),
            onShowPubkeyDetails: _showPubkeyDetails,
            onCopyPubkey: () =>
                _copyToClipboard(_userInfo['pubkey'] ?? '', 'Public Key'),
          ),
          AccountInfoActionsSection(
            onRefresh: () {
              _loadUserInfo();
              AppToast.showInfo(context, 'Account info refreshed');
            },
            onLogout: _showLogoutDialog,
          ),
          const AccountInfoAboutSection(),
        ],
      ),
    );
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
                await _authService.logout();
                if (!mounted) return;
                AppToast.showSuccess(this.context, 'Logged out successfully');
                GoRouter.of(this.context).go('/login');
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
}
