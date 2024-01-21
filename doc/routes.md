A `TreeStateRouter` has a list of routes, each of which provides visuals for a specific state in a 
state tree.  These routes come in several varieties, described below.

## StateRoute
A `StateRoute` provides visuals for a plain state (that is, not a data state). When the state is 
active in the state tree, `TreeStateRouter` will call the builder from the route to obtain the 
`Widget` that displays the state, and place it on top of the navigation stack.  

The builder function is provided a `StateRoutingContext` that may be used to post messages to the 
state machine in response to user input.

For example:

```dart
StateRoute(
   // This route provides visuals for state1.
   States.state1,
   // This builder function creates a widget that displays state1.
   routeBuilder: (BuildContext ctx, StateRoutingContext stateCtx) {
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


## DataStateRoute
`DataStateRoute<D>` provides visuals for a data state, and works in a similar manner to 
`StateRoute`. The main difference is that the `routeBuilder` and `routePageBuilder` functions for a
`DataStateRoute` are provided the current value of the state data for the state, allowing it to be 
used when displaying the state. If the state data changes as a result of message processing by the 
state machine, the builder function will be called again with the updated data.

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

There are several related convenience classes (`DataStateRoute2<D, DAnc>`, 
`DataStateRoute3<D, DAnc1, DAnc2>`, etc.) that work in a similar way to `DataStateRoute`, but 
provide data from ancestor data states to the route builder functions. 


## Shell Routes
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

## Popup Routes
Both `StateRoute` and `DataStateRoute` provide `popup` factory methods. When using these factories,
the visuals produced by the `routeBuilder` are displayed in a modal popup. As a result, the visuals
should be sized such that they do not occupy the entire available screen space, otherwise the popup
effect will not be obvious.

```dart
StateRoute.popup(
   States.edit,
   routeBuilder: (context, stateCtx) => Container(
      padding: const EdgeInsets.all(10),
      child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         mainAxisSize: MainAxisSize.min,
         children: <Widget>[
         const Text('This is a popup'),
         // In order to dismiss the popup, post a message to the state machine to cause a 
         // state transition.
         button('Done', () => stateCtx.currentState.post(Messages.endEdit)),
         ],
      ),
   ),
);
```

## Machine Routes
The `StateRoute.machine` factory constructs a route the can display visuals for the active states
in a nested state machine. The factory is similar to the `StateMachine.shell` factory, in that 
requires a list of routes corresponding to states in the nested state machine. Also, the 
`routeBuilder` function is provided a `nestedRouter` that represents the visuals for the active 
states in the nested state machine, as well as a `MachineTreeStateData` that provides access to 
nested machine.

Refer to the [MachineState](https://pub.dev/documentation/tree_state_machine/latest/delegate_builders/MachineState-class.html) 
documentation for more details on machine states,
