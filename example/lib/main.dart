import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'package:tree_state_router_examples/state_trees/simple/simple_state_tree.dart';
import 'package:tree_state_router_examples/state_trees/simple/simple_state_tree_pages.dart';

void main() {
  _initLogging();
  runApp(const MainApp());
}

final router = TreeStateRouting(
  stateMachine: TreeStateMachine(simpleStateTree()),
  defaultLayout: (_, content) => Scaffold(
    body: StateTreeInspector(
      child: Center(
        child: content,
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
