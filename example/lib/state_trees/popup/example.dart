import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'package:tree_state_router_examples/helpers/helpers.dart';
import 'state_tree.dart';
import 'pages.dart';

void main() {
  _initLogging();
  runApp(const MainApp());
}

final router = TreeStateRouter(
  stateMachine: TreeStateMachine(countingStateTree()),
  defaultScaffolding: defaultScaffolding,
  routes: [
    TreeStateRoute1(
      States.view,
      ancestorStateKey: States.counting,
      routeBuilder: viewCounterPage,
    ),
    TreeStateRoute1.popup(
      States.edit,
      ancestorStateKey: States.counting,
      routeBuilder: editCounterPage,
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
