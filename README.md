# tree_state_router

A routing package for Flutter than provides application navigation in response to the state 
transitions that take place in a [tree_state_machine](https://pub.dev/packages/tree_state_machine).


## Features

* Flutter router built for the Router API.
* Supports declarative routing based on the active states of a `TreeStateMachine`.
* Supports nested routers
* Supports URL paths and deep linking

## Documentation
See the API documentation for details on the following topics:

- [Getting started](https://pub.dev/documentation/tree_state_router/latest/topics/Getting%20Started-topic.html)
- [Routes](https://pub.dev/documentation/tree_state_router/latest/topics/Routes-topic.html)
- [Web Apps](https://pub.dev/documentation/tree_state_router/latest/topics/Web%20Apps-topic.html)
- [Deep Linking](https://pub.dev/documentation/tree_state_router/latest/topics/Deep%20Linking-topic.html)


## Imperative Routing 
In general, using imperative routing with `tree_state_router` will be infrequently used. After all,
the point of `tree_state_router` is declarative routing! However, pushing and popping routes with
`Navigator` is possible and supported. Note though that any state machine transitions that cause a 
new `StateRoute` to be activated will remove any imperative routes from the navigation stack. 
Moreover, named routes are not supported, and an error will be thrown if any `Navigator` methods 
related to named routes are called.