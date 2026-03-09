import 'package:go_router/go_router.dart';

import 'package:noscall/call/call_ui/calling_page.dart';
import 'package:noscall/call/calling_controller.dart';

/// Call route: in-call page.
List<RouteBase> get callRoutes => [
      GoRoute(
        path: '/call',
        name: 'call',
        builder: (context, state) {
          final controller = state.extra as CallingController;
          return CallingPage(controller: controller);
        },
      ),
    ];
