import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'contact_navigator.dart';
import 'pages/contact_group_list_page.dart';
import 'pages/group_contacts_page.dart';
import 'contacts_page.dart';

/// Extension for unified navigation API in contact module
extension ContactNavigationExtension on BuildContext {
  void pushContactPage(Widget page, {String? key}) {
    final navigatorState = ContactNavigatorProvider.of(this);
    if (navigatorState != null) {
      navigatorState.pushPage(
        page,
        key ?? 'contact-page-${DateTime.now().millisecondsSinceEpoch}',
      );
    } else {
      // Fallback to global router if not in contact navigator
      // This shouldn't happen, but provides safety
      debugPrint(
        'Warning: pushContactPage called outside ContactNavigator. Context: $runtimeType',
      );
    }
  }

  void popContactPage<T extends Object?>([T? result]) {
    final navigatorState = ContactNavigatorProvider.of(this);
    if (navigatorState != null) {
      // Use Navigator.pop to ensure return value is properly handled
      final navigator = Navigator.of(this);
      if (navigator.canPop()) {
        navigator.pop(result);
      }
    } else {
      // Fallback to global router
      if (canPop()) {
        pop(result);
      }
    }
  }

  bool canPopContactPage() {
    // Get ContactNavigatorProvider to check pages count
    final provider =
        dependOnInheritedWidgetOfExactType<ContactNavigatorProvider>();
    if (provider != null) {
      return provider.pagesCount > 1;
    }
    return canPop();
  }

  void pushContactsList() {
    pushContactPage(const ContactsPage(), key: 'contacts-list');
  }

  void pushGroupList() {
    pushContactPage(const ContactGroupListPage(), key: 'contacts-groups');
  }

  /// Push group contacts page using internal navigation
  Future<int?> pushGroupContacts(int groupId, String groupName) async {
    final navigatorState = ContactNavigatorProvider.of(this);
    if (navigatorState != null) {
      final page = GroupContactsPage(groupId: groupId, groupName: groupName);
      navigatorState.pushPage(page, 'group-contacts-$groupId');
      // For internal navigation, we can't easily get the return value
      // The return value will be handled by the Navigator's onPopPage callback
      // For now, return null. If needed, we can implement a callback mechanism.
      return null;
    } else {
      // Fallback to global router if not in contact navigator
      return push<int>(
        '/group-contacts',
        extra: {'groupId': groupId, 'groupName': groupName},
      );
    }
  }
}
