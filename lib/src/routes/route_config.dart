import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';

class StateRoutingContext {
  StateRoutingContext(this.currentState);
  final CurrentState currentState;
  final TreeStateRoutingState routingState = TreeStateRoutingState();
}

/// TBD: This will contain routing information parsed from the current URI.
class TreeStateRoutingState {}

/// Provides an accessor for a [StateRouteConfig] describing a route.
abstract class StateRouteConfigProvider {
  /// A config object providing a generalized description of a route for a
  /// [TreeStateRouter].
  //StateRouteConfig get config;
  StateRouteConfig createConfig(StateRouteConfig? parent);
}

/// {@template StateRouteBuilder}
/// A function that can build a widget providing a visualization of an active
/// state in a state tree.
///
/// The function is provided a build [context], and a [stateContext] that
/// describes the state to be visualized.
/// {@endtemplate}
typedef StateRouteBuilder = Widget Function(
  BuildContext context,
  StateRoutingContext stateContext,
);

/// {@template StateRoutePageBuilder}
/// A function that can build a routing [Page] that provides a visualization of
/// an active state in a state tree.
///
/// The function is provided a build [context], and a [wrapPageContent] function.
/// [wrapPageContent] must be called in order to wrap the contents of the route
/// in a specialized widget that detects state transitions and re-renders this
/// route as necessary, as well as including any
/// [TreeStateRouter.defaultScaffolding] defined by the router. The return value
/// of [wrapPageContent] function should be used as the contents of the page.
///
/// ```dart
/// var routerConfig = TreeStateRouter(
///   routes: [
///     TreeStateRoute(
///       States.state1,
///       pageRouteBuilder: (buildContext, wrapPageContent) {
///         return MaterialPage(child: wrapPageContent((ctx, stateCtx) {
///            return const Text('Hello from state1');
///          }));
///       }),
///   ]);
/// ```
/// {@endtemplate}
typedef StateRoutePageBuilder = Page<void> Function(
  BuildContext context,
  Widget Function(StateRouteBuilder buildPageContent) wrapPageContent,
);

/// A generalized description of a route that can be placed in a
/// [TreeStateRouter].
///
/// This is intended for use by [TreeStateRouter], and typically not used by an
/// application directly.
class StateRouteConfig {
  StateRouteConfig(
    this.stateKey, {
    this.routeBuilder,
    this.routePageBuilder,
    this.isPopup = false,
    RoutePathConfig? path,
    this.dependencies = const [],
    required this.childRoutes,
  }) :
        // TODO: decide what to do about DataStateKey. It has an ugly toString()
        // output.
        path = path ?? RoutePath(stateKey.toString());

  /// The state key identifying the tree state associated with this route.
  final StateKey stateKey;

  /// {@macro StateRoute.path}
  final RoutePathConfig path;

  /// The builder function providing the visuals for this route.
  ///
  /// May be `null` if [routePageBuilder] is provided instead.
  final StateRouteBuilder? routeBuilder;

  /// The builder function that constructs the routing [Page] for this route.
  ///
  /// If `null`, the [TreeStateRouter] will choose an appropriate [Page] type
  /// based on the application type (Material, Cupertino, etc.).
  final StateRoutePageBuilder? routePageBuilder;

  /// Indicates if this route will display its visuals in a modal [PopupRoute].
  final bool isPopup;

  /// A list (possibly empty) of keys indentifying the data states whose data
  /// are used when producing the visuals for the state.
  ///
  /// In general these will be ancestor states of [stateKey], although if
  /// [stateKey] is a [DataStateKey] it will be present in the list as well.
  final List<DataStateKey> dependencies;

  /// The list of child routes that are are available for routing in the nested
  /// router of a shell route.
  ///
  /// The tree states for these child routes must be descendant states of the
  /// states identified by [stateKey]
  final List<StateRouteConfig> childRoutes;
}
