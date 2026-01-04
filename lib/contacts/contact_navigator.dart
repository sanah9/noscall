import 'package:flutter/material.dart';
import 'contacts_page.dart';
import 'pages/contact_group_list_page.dart';

class ContactNavigator extends StatefulWidget {
  const ContactNavigator({super.key});

  @override
  State<ContactNavigator> createState() => _ContactNavigatorState();
}

class _ContactNavigatorState extends State<ContactNavigator> {
  List<Page> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages = [
      const MaterialPage(
        key: ValueKey('contacts-groups'),
        child: ContactGroupListPage(),
      ),
      const MaterialPage(
        key: ValueKey('contacts-list'),
        child: ContactsPage(),
      ),
    ];
  }

  void pushPage(Widget page, String key) {
    if (!mounted) return;
    final pageKey = ValueKey(key);
    setState(() {
      _pages = [
        ..._pages,
        MaterialPage(
          key: pageKey,
          child: page,
        ),
      ];
    });
  }

  void popPage() {
    if (_pages.length > 1) {
      setState(() {
        _pages = _pages.sublist(0, _pages.length - 1);
      });
    }
  }

  bool _onPopPage(Route<dynamic> route, dynamic result) {
    if (!route.didPop(result)) {
      return false;
    }
    if (_pages.length > 1) {
      setState(() {
        _pages = _pages.sublist(0, _pages.length - 1);
      });
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ContactNavigatorProvider(
      state: this,
      child: Navigator(
        pages: _pages,
        onPopPage: _onPopPage,
      ),
    );
  }
}

/// Provider for accessing ContactNavigator state
class ContactNavigatorProvider extends InheritedWidget {
  final _ContactNavigatorState state;

  const ContactNavigatorProvider({
    super.key,
    required this.state,
    required super.child,
  });

  static _ContactNavigatorState? of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<ContactNavigatorProvider>();
    return provider?.state;
  }

  /// Get pages count (for canPop check)
  int get pagesCount => state._pages.length;

  @override
  bool updateShouldNotify(ContactNavigatorProvider oldWidget) {
    return false;
  }
}