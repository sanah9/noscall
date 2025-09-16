import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/core/call/contacts/contacts.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import '../utils/toast.dart';

class UserDetailPage extends StatefulWidget {
  final String pubkey;

  const UserDetailPage({
    super.key,
    required this.pubkey,
  });

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  UserDBISAR? _user;
  bool _isContact = false;
  bool _isLoading = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      // Get user data from Account
      final user = await Account.sharedInstance.getUserInfo(widget.pubkey);

      // Check if user is in contacts
      final isContact = Contacts.sharedInstance.allContacts.containsKey(widget.pubkey);

      setState(() {
        _user = user;
        _isContact = isContact;
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
      });
      AppToast.showError('Failed to load user data: $e');
    }
  }

  void _toggleContact() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isContact) {
        // Remove contact
        final result = await Contacts.sharedInstance.removeContact(widget.pubkey);
        if (result.status) {
          setState(() {
            _isContact = false;
            _isLoading = false;
          });
          AppToast.showSuccess('Contact removed successfully');
        } else {
          setState(() {
            _isLoading = false;
          });
          AppToast.showError('Failed to remove contact');
        }
      } else {
        // Add contact
        final result = await Contacts.sharedInstance.addToContact([widget.pubkey]);
        if (result.status) {
          setState(() {
            _isContact = true;
            _isLoading = false;
          });
          AppToast.showSuccess('Contact added successfully');
        } else {
          setState(() {
            _isLoading = false;
          });
          AppToast.showError('Failed to add contact');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppToast.showError('Operation failed: $e');
    }
  }

  void _startCall() {
    // TODO: Implement voice call functionality
    AppToast.showInfo('Voice call feature coming soon');
  }

  void _startVideoCall() {
    // TODO: Implement video call functionality
    AppToast.showInfo('Video call feature coming soon');
  }

  String _getDisplayName() {
    if (_user == null) return 'Unknown User';

    // Priority: nickName > name > shortEncodedPubkey
    if (_user!.nickName != null && _user!.nickName!.isNotEmpty) {
      return _user!.nickName!;
    } else if (_user!.name != null && _user!.name!.isNotEmpty) {
      return _user!.name!;
    } else {
      return _user!.shortEncodedPubkey;
    }
  }

  void _copyNpub() {
    // TODO: Implement copy to clipboard functionality
    AppToast.showSuccess('npub copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('User Details'),
          centerTitle: true,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading user data...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('User Details'),
          centerTitle: true,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
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
                'User not found',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This user may not exist or is not accessible',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showMoreOptions();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Profile Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.primaryContainer.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: colorScheme.surface,
                    backgroundImage: _user!.picture != null && _user!.picture!.isNotEmpty
                        ? NetworkImage(_user!.picture!)
                        : null,
                    child: _user!.picture == null || _user!.picture!.isEmpty
                        ? Text(
                            _getDisplayName()[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getDisplayName(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_user!.about != null && _user!.about!.isNotEmpty) ...[
                    Text(
                      _user!.about!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _isContact
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isContact ? 'Contact' : 'Not a Contact',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: _isContact
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _toggleContact,
                          icon: _isLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                              : Icon(_isContact ? Icons.person_remove : Icons.person_add),
                          label: Text(_isContact ? 'Remove Contact' : 'Add Contact'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isContact
                                ? colorScheme.error
                                : colorScheme.primary,
                            foregroundColor: _isContact
                                ? colorScheme.onError
                                : colorScheme.onPrimary,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _startCall,
                          icon: const Icon(Icons.call),
                          label: const Text('Voice Call'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            side: BorderSide(color: colorScheme.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _startVideoCall,
                          icon: const Icon(Icons.videocam),
                          label: const Text('Video Call'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.secondary,
                            side: BorderSide(color: colorScheme.secondary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // User Information
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Information',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // npub Information
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.public,
                                color: colorScheme.tertiary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Nostr Public Key (npub)',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colorScheme.outline.withOpacity(0.3),
                              ),
                            ),
                            child: SelectableText(
                              _user!.encodedPubkey,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _copyNpub,
                                  icon: const Icon(Icons.copy, size: 16),
                                  label: const Text('Copy npub'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colorScheme.primary,
                                    side: BorderSide(color: colorScheme.primary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Additional Info
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'About This User',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'This user can be contacted using their npub. You can add them to your contacts for easier access, or call them directly using the buttons above.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.block, color: colorScheme.error),
              title: Text(
                'Block User',
                style: TextStyle(color: colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement block user functionality
                AppToast.showInfo('Block user feature coming soon');
              },
            ),
            ListTile(
              leading: Icon(Icons.report, color: colorScheme.error),
              title: Text(
                'Report User',
                style: TextStyle(color: colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement report user functionality
                AppToast.showInfo('Report user feature coming soon');
              },
            ),
            ListTile(
              leading: Icon(Icons.share, color: colorScheme.primary),
              title: const Text('Share User'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share user functionality
                AppToast.showInfo('Share user feature coming soon');
              },
            ),
          ],
        ),
      ),
    );
  }
}
