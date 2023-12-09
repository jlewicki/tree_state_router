import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';

/// TBD
/// This will contain routing information parsed from the current URI.
@immutable
class TreeStateRoutingState {}

class TreeStateRoutingContext {
  TreeStateRoutingContext(this.currentState);
  final CurrentState currentState;
  final TreeStateRoutingState routingState = TreeStateRoutingState();
}

typedef TreeStateRoutePageBuilder = Page<dynamic> Function(
  BuildContext context,
  TreeStateRoutingContext stateContext,
);

typedef TreeStateRouteWidgetBuilder = Widget Function(
  BuildContext context,
  TreeStateRoutingContext stateContext,
);

/// A route associated with a state in a state tree, which is used to visually display the tree
/// state in a [Navigator] widget.
///
/// When the tree state identified by [stateKey] is an active state in a [TreeStateMachine], the
/// [routePageBuilder] for this route is used to produce the widget that visualizes the state.
class TreeStateRoute {
  TreeStateRoute(
    this.stateKey, {
    this.routePageBuilder,
    this.routeBuilder,
  });

  /// The state key identifying the tree state associated with this route.
  final StateKey stateKey;

  final TreeStateRoutePageBuilder? routePageBuilder;

  final TreeStateRouteWidgetBuilder? routeBuilder;
}
