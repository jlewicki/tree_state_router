import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';

class StateRoutingContext {
  StateRoutingContext(this.currentState);
  final CurrentState currentState;
  final TreeStateRoutingState routingState = TreeStateRoutingState();
}

/// Provides an accessor for a [StateRouteConfig] describing a route.
abstract class StateRouteConfigProvider {
  /// A config object providing a generalized description of a route for a [TreeStateRouter].
  StateRouteConfig get config;
}

/// {@template TreeStateRouteBuilder}
/// A function that can build a widget providing a visualization of an active state in a state tree.
///
/// The function is provided a build [context], and a [stateContext] that describes the state to be
/// visualized.
/// {@endtemplate}
typedef StateRouteBuilder = Widget Function(
  BuildContext context,
  StateRoutingContext stateContext,
);

/// {@template TreeStateRoutePageBuilder}
/// A function that can build a routing [Page] that provides a visualization of an active state in
/// a state tree.
///
/// The function is provided a build [context], and a [stateContext] that describes the state to be
/// visualized.
/// {@endtemplate}
typedef StateRoutePageBuilder = Page<dynamic> Function(
  BuildContext context,
  StateRoutingContext stateContext,
);

/// A generalized description of a route that can be placed in a [TreeStateRouter].
///
/// This is intended for use by [TreeStateRouter], and typically not used by an applciation
/// directly.
class StateRouteConfig {
  StateRouteConfig(
    this.stateKey, {
    this.routeBuilder,
    this.routePageBuilder,
    this.isPopup = false,
    this.dependencies = const [],
  });

  /// The state key identifying the tree state associated with this route.
  final StateKey stateKey;

  /// {@macro StateRoute.routeBuilder}
  final StateRouteBuilder? routeBuilder;

  /// {@macro StateRoute.routePageBuilder}
  final StateRoutePageBuilder? routePageBuilder;

  /// {@macro StateRoute.isPopup}
  final bool isPopup;

  /// A list (possibly empty) of keys indentifying the data states whose data are used when
  /// producing the visuals for the state.
  ///
  /// In general these will be ancestor states of [stateKey], although if [stateKey] is a
  /// [DataStateKey] it will be present in the list as well.
  final List<DataStateKey> dependencies;
}
