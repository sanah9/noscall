import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension NavigationHelper on BuildContext {
  void safePop<T extends Object?>([T? result]) {
    if (Navigator.of(this).canPop()) {
      Navigator.of(this).pop(result);
    } else {
      try {
        pop(result);
      } catch (e) {
        debugPrint('Cannot pop: $e');
      }
    }
  }

  bool canSafePop() {
    return Navigator.of(this).canPop();
  }
}