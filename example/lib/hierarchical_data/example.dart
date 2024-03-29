import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';
import '../../helpers/helpers.dart';
import '../../helpers/state_trees/hierarchical_data.dart';
import 'pages.dart';

//
// This example demonstrates accessing and updating state and ancestor state data in a route for
// a leaf state.
//
// Each route displays all relevant state data belonging to active states, whether it belongs to the
// state for the route, or one of its ancestor states.
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
    DataStateRoute2(
      States.child1,
      ancestorStateKey: States.parent,
      routeBuilder: child1Page,
    ),
    DataStateRoute2(
      States.child2,
      ancestorStateKey: States.parent,
      routeBuilder: child2Page,
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
