import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'state_tree.dart';
import 'pages.dart';

//
// This example demonstrates a routing for a relatively simple, non-hierarchical, state machine.
//
void main() {
  _initLogging();
  runApp(const MainApp());
}

final router = TreeStateRouter(
  stateMachine: TreeStateMachine(simpleStateTree()),
  defaultScaffolding: (_, pageContent) => Scaffold(
    body: StateTreeInspector(
      child: Center(
        child: pageContent,
      ),
    ),
  ),
  enableDeveloperLogging: true,
  routes: [
    StateRoute(States.enterText, routeBuilder: enterTextPage),
    DataStateRoute(States.showLowercase, routeBuilder: toLowercasePage),
    DataStateRoute(States.showUppercase, routeBuilder: toUppercasePage),
    StateRoute(States.finished, routeBuilder: finishedPage),
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
