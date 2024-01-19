import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';

/// Provides information about the current route, including the current state
/// of a [TreeStateMachine].
///
/// This is typically automatically provided as an argument to
/// [StateRouteBuilder] and [StateRoutePageBuilder] functions, but may also
/// be accessed as an inherited widget dependency tree using
/// [StateRoutingContextProvider.of].
class StateRoutingContext {
  /// Constructs a [StateRoutingContext].
  StateRoutingContext(this.currentState, {this.platformUri});

  /// The current state of a [TreeStateMachine].
  final CurrentState currentState;

  /// The URI that was provided by the platform, if following a deep link.
  final Uri? platformUri;

  /// Unmodifiable map of the query parameters from the URI provided by the
  /// platform, when following a deep link.
  ///
  /// The map is empty if there were no query parameters, or if a deep link is
  /// not being followed.
  Map<String, String> get queryParams =>
      platformUri?.queryParameters ?? const {};

  // Provide value equality, because StateMachineRoutingInfoProvider needs to
  // detect when to values are different.
  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is StateRoutingContext &&
        other.currentState == currentState &&
        other.platformUri == platformUri;
  }

  @override
  int get hashCode => Object.hash(runtimeType, currentState, platformUri);
}

/// Provides support for building a [StateRouteInfo] that describes a route in
/// a [TreeStateRouter].
abstract class StateRouteInfoBuilder {
  /// Creates a [StateRouteInfo] providing a generalized description of a route
  /// for use by [TreeStateRouter].
  ///
  /// A [parent] is provided, indicating the parent route of the route to be
  /// created, or `null` if the route should have no parent.
  StateRouteInfo buildRouteInfo(StateRouteInfo? parent);
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

/// {@template StateRoutePageWrapper}
/// A function that can wrap content to be displayed in a routing [Page] with
/// a specialized widget that detects state machine transitions and re-renders
/// the route as necessary.
///
/// The function should be passed a [buildPageContent] function that creates the
/// widget representing the main page content.
///
/// {@endtemplate}
typedef StateRoutePageWrapper = Widget Function(
  StateRouteBuilder buildPageContent,
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
  StateRoutePageWrapper wrapPageContent,
);

/// A generalized description of a route that can be placed in a
/// [TreeStateRouter].
///
/// This is intended for use by [TreeStateRouter], and typically not used by an
/// application directly.
class StateRouteInfo {
  StateRouteInfo(
    this.stateKey, {
    this.routeBuilder,
    this.routePageBuilder,
    this.isPopup = false,
    RoutePathInfo? path,
    List<DataStateKey> dependencies = const [],
    required List<StateRouteInfo> childRoutes,
    required this.parentRoute,
  })  : dependencies = List.unmodifiable(dependencies),
        // Child routes are populated in two stages, so use UnmodifiableListView
        // here
        childRoutes = UnmodifiableListView(childRoutes),
        path = path ?? RoutePath(stateKey.toString());

  /// The state key identifying the tree state associated with this route.
  final StateKey stateKey;

  /// {@macro StateRoute.path}
  final RoutePathInfo path;

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

  /// Unmodifiable list (possibly empty) of keys indentifying the data states
  /// whose data are used when producing the visuals for the state.
  ///
  /// In general these will be ancestor states of [stateKey], although if
  /// [stateKey] is a [DataStateKey] it will be present in the list as well.
  final List<DataStateKey> dependencies;

  /// The list of child routes that are are available for routing in the nested
  /// router of a shell route.
  ///
  /// The tree states for these child routes must be descendant states of the
  /// states identified by [stateKey]
  final List<StateRouteInfo> childRoutes;

  /// The parent shell route of this route, or `null` if the route has no
  /// parent.
  ///
  /// If not `null`, then this routes is present in the `childRoutes` list of
  /// the parent.
  final StateRouteInfo? parentRoute;
}
