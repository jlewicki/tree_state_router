import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';
import '../../helpers/helpers.dart';
import '../../helpers/state_trees/hierarchical_data.dart';
import 'pages.dart';

//
// This example demonstrates accessing and updating state and ancestor state data with nested
// routers.
//
// The top level route for the parent state displays and updates the parent state data, and
// presents child states using a nested router. The parent route in this case can be thought of a
// kind of 'layout' or 'shell' route in this case.
//
void main() {
  _initLogging();
  runApp(const MainApp());
}

final router = TreeStateRouter(
  stateMachine: TreeStateMachine(hierarchicalDataStateTree()),
  defaultScaffolding: defaultScaffolding,
  enableDeveloperLogging: true,
  routes: [
    DataStateRoute.shell(
      States.parent,
      routeBuilder: parentPage,
      routes: [
        DataStateRoute(States.child1, routeBuilder: child1Page),
        DataStateRoute(States.child2, routeBuilder: child2Page),
      ],
    )
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
