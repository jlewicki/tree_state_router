# tree_state_router

A routing package for Flutter than provides application navigation in response to the state 
transitions that take place in a [tree_state_machine](https://pub.dev/packages/tree_state_machine).


## Features

* Flutter router built for the Router API.
* Supports declarative routing based on the active states of flat and hierarchical state machines.
* Supports nested routers
* Supports URL paths and deep linking

## Getting started

The `tree_state_router` package assumes you are using the `tree_state_machine` package, and would 
like to provide visuals for the states in a `TreeStateMachine`, transitioning between pages as the 
active states change.

Once a `TreeStateMachine` has been created, it can be passed to a `TreeStateRouter`, along with a 
collection of `TreeStateRoute`s that indicate how states in the state machine should be displayed. 

Each route specifies a builder function that is called to produce a `Widget` that displays a 
particular tree state. The function is passed an accessor for the `CurrentState` of the state 
machine, which can be used to post messages to the state machine in response to user input, 
potentially triggering a transition to a new tree state. The `TreeStateRouter` detects the 
transition, and navigates to the `TreeStateRoute` corresponding to the new state. 

The following example illustrates these steps.
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
A `StateRoute` provides visuals for a plain state (that is, not a data state). When the state is 
active in the state tree, `TreeStateRouter` will call the builder from the route to obtain the 
`Widget` that displays the state, and place it on top of the navigation stack.  

The builder function is provided a `TreeStateRoutingContext` that may be used to post messages to 
the state machine in response to user input.

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

There are several related convenience classes (`StateRoute1<DAnc>`, `StateRoute2<DAnc1, DAnc2>`, 
etc.) that work in a similar way to `StateRoute`, but provide data from ancestor data states to the
route builder functions. 

### DataStateRoute
`DataStateRoute<D>` provides visuals for a data state, and works in a similar manner to 
`StateRoute`. The main difference is that the `routeBuilder` for a `DataStateRoute` is provided the current value of the state data for the state, allowing it to be used when displaying the state. If
the state data changes as a result of message processing by the state machine, the `routeBuilder`
will be called again with the updated data.

```dart
class CounterData {
  CounterData(this.counter);
  final int counter;
}

class States {
  static const counting = DataStateKey<CounterData>("counting");
}

var stateTree = StateTree(
    InitialChild(States.counting),
    childStates: [
      DataState<CounterData>(
        States.counting,
        InitialData(() => CounterData(1)),
      )
    ],
  );


var router = TreeStateRouter(
  stateMachine: TreeStateMachine(stateTree),
  routes: [
    DataStateRoute<CounterData>(
      States.counting,
      // The route builder for a DataStateRoute is provided the current state data 
      routeBuilder: (BuildContext ctx, StateRoutingContext stateCtx, CounterData data) {
         return Center(
            child: Text('The value is ${data.counter}'),
         );
      },
    ),
  ],
);

```

### Popup Routes
TODO

### Shell Routes
Both `StateRoute` and `DataStateRoute` provide `shell` factory methods. These factories permit a 
route for a parent state to provide page content that wraps the visuals of its descendant states. In
other words, the parent route can provide a common layout or 'shell' that is wraps the visuals of 
its descendant states.

When calling the `shell` method, a list of routes corresponding to descendant states must be 
provided. Additionally, the `routeBuilder` or `routePageBuilder` functions accept a `nestedRouter` 
widget that reprents the visuals for active descendant states.  The builder implementation can the 
decide where in its layout it would like to place that content. 

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
URIs representing the current route path are reported to the platform. When targeting the web 
platform, this means the browser URL will be updated as state transitions occur.

Each active route contributes a segment to the URI, and the specific text of this segment can 
controlled by the `path` value for the route. 

```dart
final router = TreeStateRouter.platformRouting(
  stateTree: routePathsStateTree(),
  routes: [
    StateRoute.shell(
      States.root,
      path: RoutePath('root'),
      routeBuilder: rootPage,
      routes: [
        StateRoute.shell(
          States.parent1,
          path: RoutePath('parent-1'),
          routeBuilder: parent1Page,
          routes: [
            DataStateRoute<ChildData>(
              States.child1,
              // The URI path will be '/root/parent-1/child/1' when this route is active 
              path: DataRoutePath('child/1'),
              routeBuilder: child1Page,
            ),
            StateRoute(
              States.child2,
              path: RoutePath('child/2'),
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

Note that by default, even though URIs are displayed in the browser for the current route path, 
these URIs do not support deep linking. If an attempt is made to directly enter the URL in the
browser address bar, the route will be ignored, and instead the URI will be interpreted as the 
base URL for the web app, and consequently the state machine will restart at its initial state.   

### Path Parameters

The `DataStateRoute.withParams` factory allows values obtained from the current data value of a
data route to be included in the path. When the `pathTemplate` includes a unique name prefixed by a
`:` character.

For example
```dart
class AdddressState {
   AddressState(this.userId, this.addressId);
   final int userId;
   final int addressId;
}

DataStateRoute<ChildData>(
   States.addressState,
   path: DataRoutePath.withParams(
      'user/:userId/address/:addressId',
      pathArgs: (data) => {
         'userId': data.userId.toString(),
         'addressId': data.addressId.toString(),
      },
   ),
```

When using `DataStateRoute.withParams`, a `pathArgs` function is required to generate a
`Map<String, String>` containing the path value for each parameter to be included in the URI. The 
function is provided the current data value of the data route as input.


## Deep Linking
A route can be enabled for deep-linking by setting `enableDeepLink` to `true` when specifying the 
`path` for the route. If the application is launched with a deep-link URI, and that URI corresponds
to a deep-link enabled route, the state machine will be transitioned to the corresponding state for 
the deep link route.  

It should be noted that enabling deep linking for a route effectively introduces state transitions 
that are not defined by the underlying state tree in use by the router. While in many cases this is
desirable, care should be taken ensure that invariants established and expected by the state tree 
are not violated when enabling a route for linking.