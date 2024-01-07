import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_machine/delegate_builders.dart';
import 'package:tree_state_machine/delegate_builders.dart' as b;
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';

//
// This example demonstrates a routing for a simple state machine with two states. State transitions
// occur in response to user input.
//
void main() {
  _initLogging();
  runApp(const MainApp());
}

// Define a simple state tree with 2 states
class States {
  static const state1 = StateKey('state1');
  static const state2 = StateKey('state2');
}

class AMessage {}

StateTree simpleStateTree() {
  return StateTree(
    InitialChild(States.state1),
    childStates: [
      b.State(
        States.state1,
        onMessage: (ctx) =>
            ctx.message == AMessage ? ctx.goTo(States.state2) : ctx.unhandled(),
      ),
      b.State(States.state2),
    ],
  );
}

// Define a router with routes for states in the state tree
var router = TreeStateRouter(
  stateMachine: TreeStateMachine(simpleStateTree()),
  defaultScaffolding: (_, pageContent) => Scaffold(body: pageContent),
  routes: [
    StateRoute(
      States.state1,
      path: RoutePath('s1'),
      routeBuilder: (BuildContext ctx, StateRoutingContext stateCtx) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('This is state 1'),
              ElevatedButton(
                onPressed: () => stateCtx.currentState.post(AMessage()),
                child: const Text('Send a message'),
              )
            ],
          ),
        );
      },
    ),
    StateRoute(
      States.state2,
      path: RoutePath('s2'),
      routeBuilder: (BuildContext ctx, StateRoutingContext stateCtx) {
        return const Center(child: Text('This is state 2'));
      },
    ),
  ],
);

// Create a router based Material app with the TreeStateRouter
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
