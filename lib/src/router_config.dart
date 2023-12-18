import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'package:tree_state_router/src/router_delegate.dart';

/// A function that can adorn the content of a route page, adding common layout or scaffolding.
///
/// The function is provided a [buildFor] indicating the reason the page is being built, and
/// the [pageContent] to display in the page.
typedef DefaultScaffoldingBuilder = Widget Function(
  PageBuildFor buildFor,
  Widget pageContent,
);

/// A function that can create a [Page] to display the content of a route.
///
/// The function is provided a [buildFor] indicating the reason the page is being built, and
/// the [pageContent] to display in the page.
///
/// The function can return `null` if the application does not require specialized page under
/// certain conditions, in which case the router will use a default [Page].
typedef DefaultPageBuilder = Page<void>? Function(
  PageBuildFor buildFor,
  Widget pageContent,
);

/// Routing information that describes how to display states in a [TreeStateMachine], and triggers
/// routing navigation in response to state transitions within the state machine.
class TreeStateRouter implements RouterConfig<TreeStateRouteInfo> {
  TreeStateRouter({
    required this.stateMachine,
    required this.routes,
    this.defaultScaffolding,
    this.defaultPageBuilder,
    this.enableTransitions = true,
  }) : assert((() {
          routes.fold(<StateKey>{}, (keys, route) {
            if (keys.contains(route.config.stateKey)) {
              throw AssertionError(
                  "There is more than one route for state '${route.config.stateKey}' defined");
            }
            keys.add(route.config.stateKey);
            return keys;
          });
          return true;
        }()));

  /// The state machine providing the tree states that are routed by this [TreeStateRouter].
  final TreeStateMachine stateMachine;

  /// The list of routes that can be materialized by this router.  Each route should correspond to a
  /// a state in the [stateMachine].
  final List<StateRouteConfigProvider> routes;

  /// {@template TreeStateRouter.defaultScaffolding}
  /// A function that can adorn the content of a route page, adding common layout or scaffolding.
  ///
  /// The function is provided a `buildFor` indicating the reason the page is being built, and
  /// the `pageContent` to display in the page.
  /// {@endtemplate}
  ///
  /// For example, this can be used to wrap the content of each page of a tree state router in a
  /// Material Scaffold widget:
  ///
  /// ```dart
  /// TreeStateRouterConfig( {
  ///   // ...
  ///   defaultLayout: (_, pageContent) => Scaffold(child: pageContent),
  /// });
  /// ```
  final DefaultScaffoldingBuilder? defaultScaffolding;

  /// {@template TreeStateRouter.defaultPageBuilder}
  /// A function that can create a [Page] to display the content of a route.
  ///
  /// The function is provided a `buildFor` indicating the reason the page is being built, and
  /// the `pageContent` to display in the page.
  /// {@endtemplate}
  final DefaultPageBuilder? defaultPageBuilder;

  /// {@template TreeStateRouter.enableTransitions}
  /// Indicates if page transitions within the router should be animated.
  ///
  /// If enabled, the particular animations that occur are determined by the [Page]s associated with
  /// the routes that are undergoing a transition.
  ///
  /// See [StateRoute.routePageBuilder] and [TreeStateRouter.defaultPageBuilder] for details on
  /// choosing a [Page] type.
  /// {@endtemplate}
  final bool enableTransitions;

  late final _routerDelegateConfig = TreeStateRouterDelegateConfig(
    routes.map((e) => e.config).toList(),
    defaultPageBuilder: defaultPageBuilder,
    defaultScaffolding: defaultScaffolding,
    enableTransitions: enableTransitions,
  );

  /// The [RouterDelegate] used by [TreeStateRouter].
  @override
  late final routerDelegate = TreeStateRouterDelegate(
    config: _routerDelegateConfig,
    stateMachine: stateMachine,
  );

  /// The [RootBackButtonDispatcher] used by [TreeStateRouter].
  @override
  final backButtonDispatcher = RootBackButtonDispatcher();

  /// The [RouteInformationParser] used by [TreeStateRouter].
  @override
  late final routeInformationParser =
      TreeStateRouteInformationParser(stateMachine.rootNode.key);

  /// The [RouteInformationProvider] used by [TreeStateRouter].
  @override
  late final routeInformationProvider = PlatformRouteInformationProvider(
    initialRouteInformation: RouteInformation(
      uri: Uri.parse(
        WidgetsBinding.instance.platformDispatcher.defaultRouteName,
      ),
    ),
  );
}
