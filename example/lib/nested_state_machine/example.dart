import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'package:tree_state_router_examples/helpers/helpers.dart';
import 'state_tree.dart';
import 'nested_state_tree.dart' as nested;
import 'pages.dart';

//
// This exmample demonstrates routing for a inner state machine nested as a machine state in an
// outer state machine.
//
void main() {
  _initLogging();
  runApp(const MainApp());
}

final router = TreeStateRouter(
  stateTree: nestedStateMachineStateTree(),
  defaultScaffolding: defaultScaffolding,
  routes: [
    StateRoute(
      States.nestedMachineReady,
      routeBuilder: nestedMachineReadyPage,
    ),
    StateRoute.machine(
      States.nestedMachineRunning,
      routeBuilder: (_, __, content) => content,
      routes: [
        StateRoute(
          nested.States.step1,
          routeBuilder: nestedMachineStep1,
        ),
        StateRoute(
          nested.States.step2,
          routeBuilder: nestedMachineStep2,
        ),
        StateRoute(
          nested.States.step3,
          routeBuilder: nestedMachineStep3,
        ),
      ],
    ),
    StateRoute(
      States.nestedMachineDone,
      routeBuilder: nestedMachineDonePage,
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
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    log('${record.level.name}: ${record.loggerName}: ${record.time}: ${record.message} ${record.error?.toString() ?? ''}');
  });
}
