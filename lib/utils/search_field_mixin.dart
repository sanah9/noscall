import 'package:flutter/material.dart';

/// Mixin that provides a search [TextEditingController] and [searchQuery] string
/// in sync with the controller, with correct init and dispose.
///
/// Usage:
/// 1. Add `with SearchFieldMixin` to your State class.
/// 2. In [initState], call [initSearchField].
/// 3. In [dispose], call [disposeSearchField].
/// 4. Use [searchController] for the TextField and [searchQuery] for filtering.
/// 5. Optionally pass [onSearchQueryChanged] to react to query changes (e.g. push to a Stream).
mixin SearchFieldMixin<T extends StatefulWidget> on State<T> {
  late final TextEditingController _searchController;
  String _searchQuery = '';
  void Function()? _searchListener;

  /// Search text controller; use this as the TextField's controller.
  TextEditingController get searchController => _searchController;

  /// Current search text; updates when the user types. Use for filtering.
  String get searchQuery => _searchQuery;

  /// Call from [initState]. Sets up the controller and listener.
  /// [onSearchQueryChanged] is invoked whenever the search text changes (e.g. for Stream-based UIs).
  void initSearchField({void Function(String)? onSearchQueryChanged}) {
    _searchController = TextEditingController();
    _searchListener = () {
      if (mounted) {
        final text = _searchController.text;
        setState(() {
          _searchQuery = text;
        });
        onSearchQueryChanged?.call(text);
      }
    };
    _searchController.addListener(_searchListener!);
  }

  /// Call from [dispose]. Removes listener and disposes the controller.
  void disposeSearchField() {
    if (_searchListener != null) {
      _searchController.removeListener(_searchListener!);
    }
    _searchController.dispose();
  }
}
