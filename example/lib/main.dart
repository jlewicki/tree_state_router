import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'simple/state_tree.dart';
import 'simple/pages.dart';

//
// This example demonstrates a routing for a relatively simple, non-hierarchical, state machine.
//
void main() {
  _initLogging();
  runApp(const MainApp());
}

final router = TreeStateRouter.platformRouting(
  stateTree: simpleStateTree(),
  defaultScaffolding: (_, pageContent) => Scaffold(
    body: StateTreeInspector(
      child: Center(
        child: pageContent,
      ),
    ),
  ),
  routes: [
    StateRoute(
      States.enterText,
      path: 'text',
      routeBuilder: enterTextPage,
    ),
    DataStateRoute(
      States.showLowercase,
      path: 'lowercase',
      routeBuilder: toLowercasePage,
    ),
    DataStateRoute(
      States.showUppercase,
      path: 'uppercase',
      routeBuilder: toUppercasePage,
    ),
    StateRoute(
      States.finished,
      //path: 'done',
      routeBuilder: finishedPage,
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
    log('${record.loggerName}: ${record.message} ${record.error?.toString() ?? ''}');
  });
}
