import 'dart:developer';

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
  routes: [
    TreeStateRoute(States.enterText, routeBuilder: enterTextPage),
    DataTreeStateRoute(States.showLowercase, routeBuilder: toLowercasePage),
    DataTreeStateRoute(States.showUppercase, routeBuilder: toUppercasePage),
    TreeStateRoute(States.finished, routeBuilder: finishedPage),
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
    log('${record.level.name}: ${record.loggerName}: ${record.time}: ${record.message} ${record.error?.toString() ?? ''}');
  });
}
