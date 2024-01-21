The `tree_state_router` package assumes you are using the
[`tree_state_machine`](https://pub.dev/packages/tree_state_machine) package, and would like to 
provide visuals for the states in a `TreeStateMachine`, transitioning between pages as the active 
states change.

To do so, a `TreeStateRouter` is created, along with a collection of `TreeStateRoute`s that indicate
how states in the state machine should be displayed.  

Each route specifies a builder function that is called to produce a `Widget` that displays a 
particular tree state. The function is passed an accessor for the `CurrentState` of the state 
machine, which can be used to post messages to the state machine in response to user input, 
potentially triggering a transition to a new tree state. The `TreeStateRouter` detects the 
transition, and navigates to the `TreeStateRoute` corresponding to the new state. 

`tree_state_router` differs from other routers (for example `go_router`) in that it is primarily 
reactive in nature, selecting routes for the current state(s) in a state machine, but not 
triggering route changes directly. In order to change the current route, a message must be posted
to the state machine that causes a state transition.  

The following example illustrates a basic usage of a `TreeStateRouter`:
```dart

import 'package:flutter/material.dart';
import 'package:tree_state_machine/delegate_builders.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';

void main() {
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
      State(
         States.state1,
         onMessage: (ctx) => switch(ctx.message) {
            AMessage() => ctx.goTo(States.state2),
            _ => ctx.unhandled(),
         }),
      State(States.state2),
    ],
  );
}

// Define a router with routes for each state in the state tree
final router = TreeStateRouter(
  stateMachine: TreeStateMachine(simpleStateTree()),
  defaultScaffolding: (_, pageContent) => Scaffold(body: pageContent),
  routes: [
    StateRoute(
      States.state1,
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
