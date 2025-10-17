import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/core/account/account.dart';
import '../core/core.dart';
import '../utils/toast.dart';

class EditNicknamePage extends StatefulWidget {
  final String pubkey;
  final String currentNickname;

  const EditNicknamePage({
    super.key,
    required this.pubkey,
    required this.currentNickname,
  });

  @override
  State<EditNicknamePage> createState() => _EditNicknamePageState();
}

class _EditNicknamePageState extends State<EditNicknamePage> {
  late TextEditingController _nicknameController;
  bool _isLoading = false;

  late ThemeData theme;
  Color get primary => theme.colorScheme.primary;
  Color get onSurface => theme.colorScheme.onSurface;
  Color get onSurfaceVariant => theme.colorScheme.onSurfaceVariant;
  Color get surface => theme.colorScheme.surface;
  Color get error => theme.colorScheme.error;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.currentNickname);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Nickname',
          style: TextStyle(color: onSurface),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurface),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveNickname,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? onSurfaceVariant : primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nickname',
              style: theme.textTheme.titleMedium?.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nicknameController,
              enabled: !_isLoading,
              maxLength: 50,
              decoration: InputDecoration(
                hintText: 'Enter nickname',
                hintStyle: TextStyle(color: onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: onSurfaceVariant.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: onSurfaceVariant.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: error),
                ),
                filled: true,
                fillColor: surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: TextStyle(color: onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'You can set a custom nickname for this contact to help you identify them.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: onSurfaceVariant,
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 24),
              Center(
                child: CircularProgressIndicator(
                  color: primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveNickname() async {
    if (_isLoading) return;

    final newNickname = _nicknameController.text.trim();
    final userNotifier = Account.sharedInstance.getUserNotifier(widget.pubkey);
    final currentUser = userNotifier.value;

    if (newNickname == currentUser.nickName) return;

    setState(() {
      _isLoading = true;
    });

    final event = await Contacts.sharedInstance.updateContactNickName(
      currentUser.pubKey,
      newNickname,
    );
    setState(() {
      _isLoading = false;
    });
    if (event.status) {
      AppToast.showSuccess(context, 'Nickname updated successfully');
      context.pop();
    } else {
      AppToast.showError(context, 'Failed to update nickname: ${event.message}');
    }
  }
}