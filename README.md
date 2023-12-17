# tree_state_router

A routing package for Flutter than provides application navigation in response to the state transitions that take 
place in a [tree_state_machine](https://pub.dev/packages/tree_state_machine) 


## Features

* Flutter router built for the Router API.
* Supports declarative routing based on the active states of flat and hierarchical state machines.
* Supports nested routers


## Getting started

The `tree_state_router` package assumes you are using the `tree_state_machine` package, and would like to provide 
visuals for the states in a `TreeStateMachine`, transitioning between pages as the active states change.

Once a `TreeStateMachine` has been created, it can be passed to a `TreeStateRouter`, along with a collection of 
`TreeStateRoute`s that indicate how states in the state machine should be displayed. 

Each route specifies a builder function that is called to produce a `Widget` that displays a particular tree state. 
The function is passed an accessor for the `CurrentState` of the state machine, which can be used to post messages to 
the state machine in response to user input, potentially triggering a transition to a new tree state. The 
`TreeStateRouter` detects the transition, and navigates to the `TreeStateRoute` corresponding to the new state. 

The following example ilustrates these steps.
```dart

import 'package:flutter/material.dart';
import 'package:tree_state_machine/tree_builders.dart';
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

StateTreeBuilder simpleStateTree() {
  var b = StateTreeBuilder(initialChild: States.state1);
  b.state(States.state1, (b) {
    b.onMessage<AMessage>((b) => b.goTo(States.state2));
  });
  b.state(States.state2, emptyState);
  return b;
}

// Define a router with routes for each state in the state tree
final router = TreeStateRouter(
  stateMachine: TreeStateMachine(simpleStateTree()),
  defaultScaffolding: (_, pageContent) => Scaffold(body: pageContent),
  routes: [
    TreeStateRoute(
      States.state1,
      routeBuilder: (BuildContext ctx, TreeStateRoutingContext stateCtx) {
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
    TreeStateRoute(
      States.state2,
      routeBuilder: (BuildContext ctx, TreeStateRoutingContext stateCtx) {
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

```

