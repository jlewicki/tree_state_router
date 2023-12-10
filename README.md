# tree_state_router

A routing package for Flutter than provides application navigation in response to the state transitions that take 
place in a [tree_state_machine](https://pub.dev/packages/tree_state_machine) 


## Features

* Flutter router built for the Router API.
* Supports declarative routing for flat and hierarchical state machines.
* Supports nested routers


## Getting started

The `tree_state_router` package assumes you are using the `tree_state_machine` package, and would like to provide visuals for the active states in a `TreeStateMachine`, transitioning betewen pages as the active states change.


```dart
import 'package:tree_state_machine/tree_state_builders.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';


var treeStateRouting = TreeStateRouting(
  stateMachine: TreeStateMachine(buildAStateTree())
  routes: [
    TreeStateRoute(
      State.state1, 
      routeBuilder: (BuildContext ctx, TreeStateRoutingContext stateCtx) {
         return Center(child: Text('This is state 1'));
      }
    ),
  ],
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: treeStateRouting,
    );
  }
}

```

