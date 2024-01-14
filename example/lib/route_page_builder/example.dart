import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';
import '../../helpers/helpers.dart';
import 'state_tree.dart';
import 'pages.dart';

//
// This example demonstrates use of `routePageBuilder`s to create the specific
// `Page<void>` values that provide content to the router.
//
void main() {
  _initLogging();
  runApp(const MainApp());
}

final router = TreeStateRouter(
  stateMachine: TreeStateMachine(hierarchicalDataStateTree()),
  defaultScaffolding: defaultScaffolding,
  enableTransitions: true,
  enableDeveloperLogging: true,
  routes: [
    DataStateRoute.shell(
      States.dataParent,
      routePageBuilder: (ctx, wrapPage) =>
          MaterialPage(child: wrapPage(dataParentPage)),
      routes: [
        StateRoute(
          States.child,
          routePageBuilder: (ctx, wrapPage) =>
              MaterialPage(child: wrapPage(childPage)),
        ),
      ],
    ),
    StateRoute.shell(
      States.parent,
      routePageBuilder: (ctx, wrapPage) =>
          MaterialPage(child: wrapPage(parentPage)),
      routes: [
        DataStateRoute(
          States.dataChild,
          routePageBuilder: (ctx, wrapPage) =>
              MaterialPage(child: wrapPage(dataChildPage)),
        ),
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
  hierarchicalLoggingEnabled = true;
}
