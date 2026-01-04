import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'contact_navigator.dart';
import 'pages/contact_group_list_page.dart';
import 'contacts_page.dart';

/// Extension for unified navigation API in contact module
extension ContactNavigationExtension on BuildContext {
  void pushContactPage(Widget page, {String? key}) {
    final navigatorState = ContactNavigatorProvider.of(this);
    if (navigatorState != null) {
      navigatorState.pushPage(page, key ?? 'contact-page-${DateTime.now().millisecondsSinceEpoch}');
    } else {
      // Fallback to global router if not in contact navigator
      // This shouldn't happen, but provides safety
      debugPrint('Warning: pushContactPage called outside ContactNavigator. Context: ${runtimeType}');
    }
  }

  void popContactPage<T extends Object?>([T? result]) {
    final navigatorState = ContactNavigatorProvider.of(this);
    if (navigatorState != null) {
      navigatorState.popPage();
    } else {
      // Fallback to global router
      if (canPop()) {
        pop(result);
      }
    }
  }

  bool canPopContactPage() {
    // Get ContactNavigatorProvider to check pages count
    final provider = dependOnInheritedWidgetOfExactType<ContactNavigatorProvider>();
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
}

