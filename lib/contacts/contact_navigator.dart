import 'package:flutter/material.dart';
import 'contacts_page.dart';
import 'pages/contact_group_list_page.dart';
import 'pages/group_contacts_page.dart';
import 'services/contact_navigation_service.dart';
import 'services/contact_group_service.dart';

class ContactNavigator extends StatefulWidget {
  const ContactNavigator({super.key, this.favoritesOnlyRoot = false});

  /// When true, shows a single [ContactsPage] with favorites filter (mobile Favorites tab).
  final bool favoritesOnlyRoot;

  @override
  State<ContactNavigator> createState() => ContactNavigatorState();
}

class ContactNavigatorState extends State<ContactNavigator> {
  List<Page> _pages = [];
  late Future _initialize;

  @override
  void initState() {
    super.initState();
    _initialize = _initializePages();
  }

  Future<void> _initializePages() async {
    if (widget.favoritesOnlyRoot) {
      _pages = [
        const MaterialPage(
          child: ContactsPage(
            initialShowFavoritesOnly: true,
            favoritesOnlyNavEntry: true,
          ),
        ),
      ];
      return;
    }

    final navService = ContactNavigationService.sharedInstance;
    final groupId = await navService.getLastGroupId();
    _pages = [const MaterialPage(child: ContactGroupListPage())];

    Widget page = const ContactsPage();
    if (groupId != null) {
      page = await _getGroupPage(groupId) ?? page;
    }
    _pages.add(MaterialPage(child: page));
  }

  Future<Widget?> _getGroupPage(int groupId) async {
    try {
      final groupService = ContactGroupService.sharedInstance;
      final groups = await groupService.getAllGroups();
      final group = groups.firstWhere(
        (g) => g.id == groupId,
        orElse: () => throw Exception('Group not found'),
      );

      return GroupContactsPage(groupId: groupId, groupName: group.name);
    } catch (e) {
      ContactNavigationService.sharedInstance.clearLastGroupId();
    }

    return null;
  }

  void pushPage(Widget page, String key) {
    if (!mounted) return;
    final pageKey = ValueKey(key);
    setState(() {
      _pages = [..._pages, MaterialPage(key: pageKey, child: page)];
    });
  }

  void popPage() {
    if (_pages.length > 1) {
      setState(() {
        _pages = _pages.sublist(0, _pages.length - 1);
      });
    }
  }

  void _onDidRemovePage(Page<Object?> page) {
    if (_pages.length <= 1) return;
    setState(() {
      _pages = List<Page>.from(_pages)..remove(page);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialize,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container();
        }
        return ContactNavigatorProvider(
          state: this,
          child: Navigator(pages: _pages, onDidRemovePage: _onDidRemovePage),
        );
      },
    );
  }
}

/// Provider for accessing ContactNavigator state
class ContactNavigatorProvider extends InheritedWidget {
  final ContactNavigatorState state;

  const ContactNavigatorProvider({
    super.key,
    required this.state,
    required super.child,
  });

  static ContactNavigatorState? of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ContactNavigatorProvider>();
    return provider?.state;
  }

  /// Get pages count (for canPop check)
  int get pagesCount => state._pages.length;

  @override
  bool updateShouldNotify(ContactNavigatorProvider oldWidget) {
    return false;
  }
}
