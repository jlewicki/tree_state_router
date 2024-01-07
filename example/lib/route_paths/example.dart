import 'dart:developer';
//import 'package:flutter_web_plugins/url_strategy.dart';
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
  //usePathUrlStrategy();
  _initLogging();
  runApp(const MainApp());
}

final router = TreeStateRouter.platformRouting(
  stateTree: routePathsStateTree(),
  routes: [
    StateRoute.shell(
      States.root,
      path: RoutePath('root'),
      routeBuilder: rootPage,
      routes: [
        StateRoute.shell(
          States.parent1,
          path: RoutePath('parent-1'),
          routeBuilder: parent1Page,
          routes: [
            DataStateRoute<ChildData>(
              States.child1,
              path: DataRoutePath.withParams(
                'child1/:id',
                pathArgs: (data) => {"id": data.id.toString()},
                initialData: (pathArgs) {
                  return ChildData(int.parse(pathArgs['id']!), 0);
                },
                enableDeepLink: true,
              ),
              routeBuilder: child1Page,
            ),
            StateRoute(
              States.child2,
              path: RoutePath('child2'),
              routeBuilder: child2Page,
            )
          ],
        ),
        StateRoute.shell(
          States.parent2,
          path: RoutePath('parent-2'),
          routeBuilder: parent2Page,
          routes: [
            StateRoute(
              States.child3,
              path: RoutePath('child-3', enableDeepLink: true),
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
