import 'package:flutter/material.dart';
import 'pages/contact_group_list_page.dart';
import 'contacts_page.dart';

class ContactNavigator extends StatefulWidget {
  const ContactNavigator({super.key});

  @override
  State<ContactNavigator> createState() => _ContactNavigatorState();
}

class _ContactNavigatorState extends State<ContactNavigator> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final List<Page> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.add(
      const MaterialPage(
        key: ValueKey('contacts-list'),
        child: ContactsPage(),
      ),
    );
  }

  bool _onPopPage(Route<dynamic> route, dynamic result) {
    if (_pages.length > 1) {
      setState(() {
        _pages.removeLast();
      });
      return true;
    }
    return false;
  }

  void pushGroupListPage() {
    setState(() {
      _pages.add(
        const MaterialPage(
          key: ValueKey('group-list'),
          child: ContactGroupListPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ContactNavigatorProvider(
      state: this,
      child: Navigator(
        key: navigatorKey,
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

  @override
  bool updateShouldNotify(ContactNavigatorProvider oldWidget) {
    return false;
  }
}

