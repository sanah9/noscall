import 'package:flutter/material.dart';

/// Generic add/edit entry dialog: title, single text input, optional helper/trailing, confirm/cancel.
/// Returns the trimmed string when user confirms, null when cancelled.
Future<String?> showCrudEntryDialog({
  required BuildContext context,
  required String title,
  String hintText = '',
  String? helperText,
  Widget? trailing,
  String initialValue = '',
  String confirmLabel = 'Save',
  String cancelLabel = 'Cancel',
}) async {
  final controller = TextEditingController(text: initialValue);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              border: const OutlineInputBorder(),
              helperText: helperText,
            ),
            autofocus: true,
          ),
          if (trailing != null) ...[
            const SizedBox(height: 8),
            trailing,
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () {
            final value = controller.text.trim();
            if (value.isNotEmpty) {
              Navigator.of(context).pop(value);
            }
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result;
}
