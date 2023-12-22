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
    StateRoute(
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
    StateRoute(
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

## Routes
### StateRoute
A `StateRoute` provides visuals for a plain state (that is, not a data state). When the state is active in the state 
tree, `TreeStateRouter` will call the builder from the route to obtain the `Widget` that displays the state, and place
it on top of the navigation stack.  

The builder function is provided a `TreeStateRoutingContext` that may be used to post messages to the state machine 
in response to user input.

For example:

```dart
StateRoute(
   // This route provides visuals for state1.
   States.state1,
   // This builder function creates a widget that displays state1.
   routeBuilder: (BuildContext ctx, TreeStateRoutingContext stateCtx) {
      return Center(
         child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
            const Text('This is state 1'),
            ElevatedButton(
               // When the button is pressed, send a message to the state machine
               onPressed: () => stateCtx.currentState.post(AMessage()),
               child: const Text('Send a message'),
            )
         ],
         ),
      );
   },
),
```

### DataStateRoute
TODO

### Popup Routes
TODO

### Shell Routes
Both `StateRoute` and `DataStateRoute` provide `shell` factory methods. These factories permit a route for a parent 
state to provide page content that wraps the visuals of its descendant states. In other words, the parent route can 
provide a common layout or 'shell' that is wraps the visuals of its descendant states.

When calling the `shell` method, a list of routes corresponding to descendant states must be provided. Additionally,
the `routeBuilder` or `routePageBuilder` functions accept a `nestedRouter` widget that reprents the visuals for active
descendant states.  The builder implementation can the decide where in its layout it would like to place that content. 

```dart
StateRoute.shell(
   States.parent,
   routeBuilder: (_, __, nestedRouter) => Scaffold(
      body: Center(
         child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Text('This the parent'),
               // Visuals for descendant states appear here
               Expanded(child: nestedRouter),
            ],
         ),
      ),
   ),
   routes: [
      StateRoute(States.child1,
         routeBuilder: (_, __) => Center(child: Text('This is child1'))),
      StateRoute(States.child2,
         routeBuilder: (_, __) => Center(child: Text('This is child2'))),
   ],
)
```

## Web
If the `TreeStateRouter.platformRouting` factory is used, the router will integrate with the 
Navigator 2.0 APIs.

### Route URIs
 URIs representing the current report path are reported to the platform. When targeting the web 
platform, this means the browser URL will be updated as state transitions occur.

Each active route contributes a segment to the URI, and the specific text of this segment can 
controlled by the `path` value for the route. 

```dart
final router = TreeStateRouter.platformRouting(
  stateTree: routePathsStateTree(),
  routes: [
    StateRoute.shell(
      States.root,
      path: const RoutePathConfig('root'),
      routeBuilder: rootPage,
      routes: [
        StateRoute.shell(
          States.parent1,
          path: const RoutePathConfig('parent-1'),
          routeBuilder: parent1Page,
          routes: [
            DataStateRoute(
              States.child1,
              // The URI path will be '/root/parent-1/child/1' when this route is active 
              path: const RoutePathConfig('child/1'),
              routeBuilder: child1Page,
            ),
            StateRoute(
              States.child2,
              path: const RoutePathConfig('child/2'),
              routeBuilder: child2Page,
            )
          ],
        ),
    ),
  ],
);
```


If `path` is left undefined, the `stateKey` will be used as a fallback to generate the URI segment.
This is unlikely to be appropriate for end users, so it is recommended that `path` values be 
provided for all routes. 

## Deep Linking
Not eyet supported.