import 'package:flutter/material.dart';

/// Mixin that provides a search [TextEditingController] and [searchQuery] string
/// in sync with the controller, with correct init and dispose.
///
/// Usage:
/// 1. Add `with SearchFieldMixin` to your State class.
/// 2. In [initState], call [initSearchField].
/// 3. In [dispose], call [disposeSearchField].
/// 4. Use [searchController] for the TextField and [searchQuery] for filtering.
mixin SearchFieldMixin<T extends StatefulWidget> on State<T> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  /// Search text controller; use this as the TextField's controller.
  TextEditingController get searchController => _searchController;

  /// Current search text; updates when the user types. Use for filtering.
  String get searchQuery => _searchQuery;

  /// Call from [initState]. Sets up the controller and listener.
  void initSearchField() {
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  /// Call from [dispose]. Removes listener and disposes the controller.
  void disposeSearchField() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {
        _searchQuery = _searchController.text;
      });
    }
  }
}
