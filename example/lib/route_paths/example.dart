import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'state_tree.dart';
import 'pages.dart';

//
// This example demonstrates use of RoutePathConfig with routes to control how routes are converted
// to path segments in the route URL, as well as enabling some routes for
// deep-linking.
//
void main() {
  _initLogging();
  runApp(const MainApp());
}

final router = TreeStateRouter.platformRouting(
  stateTree: routePathsStateTree(),
  routes: [
    StateRoute.shell(
      States.root,
      path: const RoutePathConfig('root'),
      routeBuilder: rootPage,
      routes: [
        StateRoute.shell(
          States.parent1,
          path: const RoutePathConfig('parent-1'),
          routeBuilder: parent1Page,
          routes: [
            DataStateRoute(
              States.child1,
              path: const RoutePathConfig('child/1', enableDeepLink: true),
              routeBuilder: child1Page,
            ),
            StateRoute(
              States.child2,
              path: const RoutePathConfig('child/2'),
              routeBuilder: child2Page,
            )
          ],
        ),
        StateRoute.shell(
          States.parent2,
          path: const RoutePathConfig('parent-2'),
          routeBuilder: parent2Page,
          routes: [
            StateRoute(
              States.child3,
              path: const RoutePathConfig('child-3', enableDeepLink: true),
              routeBuilder: child3Page,
            )
          ],
        )
      ],
    ),
  ],
);

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
    );
  }
}

void _initLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    log('${record.level.name}: ${record.loggerName}: ${record.message} ${record.error?.toString() ?? ''}');
  });
}
