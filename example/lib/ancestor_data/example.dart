import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'state_tree.dart';
import 'pages.dart';

//
// This example demonstrates routes that access data from ancestor states
//
void main() {
  _initLogging();
  runApp(const MainApp());
}

final router = TreeStateRouter(
  stateMachine: TreeStateMachine(readAncestorDataStateTree()),
  defaultScaffolding: (_, pageContent) => Scaffold(
    body: StateTreeInspector(
      child: Center(
        child: pageContent,
      ),
    ),
  ),
  routes: [
    DataStateRoute3(
      States.dataChild,
      ancestor1StateKey: States.parent,
      ancestor2StateKey: States.root,
      routeBuilder: dataChildPage,
    ),
    StateRoute2(
      States.child,
      ancestor1StateKey: States.parent,
      ancestor2StateKey: States.root,
      routeBuilder: childPage,
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
    log('${record.level.name}: ${record.loggerName}: ${record.time}: ${record.message} ${record.error?.toString() ?? ''}');
  });
}
