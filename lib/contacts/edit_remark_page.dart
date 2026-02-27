import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/core/navigation/app_navigator_scope.dart';
import 'package:noscall/utils/toast.dart';
import 'services/contact_remark_service.dart';

class EditRemarkPage extends StatefulWidget {
  final String pubkey;
  final String currentRemark;

  const EditRemarkPage({
    super.key,
    required this.pubkey,
    required this.currentRemark,
  });

  @override
  State<EditRemarkPage> createState() => _EditRemarkPageState();
}

class _EditRemarkPageState extends State<EditRemarkPage> {
  late TextEditingController _remarkController;
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
    _remarkController = TextEditingController(text: widget.currentRemark);
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Remark',
          style: TextStyle(color: onSurface),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurface),
          onPressed: () =>
              AppNavigatorScope.requireOf(context).pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveRemark,
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
              'Remark',
              style: theme.textTheme.titleMedium?.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _remarkController,
              enabled: !_isLoading,
              maxLength: 200,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add a note for this contact',
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
              'Private note shown only on your device.',
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

  Future<void> _saveRemark() async {
    if (_isLoading) return;

    final newRemark = _remarkController.text.trim();
    final current = ContactRemarkService().getRemark(widget.pubkey);
    if (newRemark == (current ?? '')) {
      AppNavigatorScope.requireOf(context).pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await ContactRemarkService().setRemark(widget.pubkey, newRemark);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      AppToast.showSuccess(context, 'Remark saved');
      AppNavigatorScope.requireOf(context).pop(context);
    }
  }
}
