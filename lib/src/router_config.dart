import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/pages.dart';
import 'package:tree_state_router/src/parser.dart';
import 'package:tree_state_router/src/router_delegate.dart';
import 'package:tree_state_router/src/routes.dart';

/// {@template DefaultScaffoldingBuilder}
/// A function that can adorn the content of a route page, adding common layout or scaffolding.
///
/// The function is provided a [buildFor] indicating the reason the page is being built, and
/// the [pageContent] to display in the page.
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
/// {@endtemplate}
typedef DefaultScaffoldingBuilder = Widget Function(PageBuildFor buildFor, Widget pageContent);

/// {@template DefaultPageBuilder}
/// A function that can create a [Page] to display the content of a route.
///
/// The function is provided a [buildFor] indicating the reason the page is being built, and
/// the [pageContent] to display in the page.
/// {@endtemplate}
typedef DefaultPageBuilder = Page<void> Function(PageBuildFor buildFor, Widget pageContent);

/// Routing information that describes how to display states in a [TreeStateMachine], and triggers
/// routing navigation in response to state transitions within the state machine.
class TreeStateRouter implements RouterConfig<TreeStateRouteInfo> {
  TreeStateRouter({
    required this.stateMachine,
    required this.routes,
    this.defaultScaffolding,
    this.defaultPageBuilder,
    this.enableTransitions = true,
  });

  /// The state machine providing the tree states that are routed by this [TreeStateRouter].
  final TreeStateMachine stateMachine;

  /// The list of routes that can be materialized by this router.  Each route should correspond to a
  /// a state in the [stateMachine].
  final List<TreeStateRoute> routes;

  /// {@macro DefaultScaffoldingBuilder}
  final DefaultScaffoldingBuilder? defaultScaffolding;

  /// {@macro DefaultPageBuilder}
  final DefaultPageBuilder? defaultPageBuilder;

  /// Indicates if page transitions within the router should be animated.
  ///
  /// If enabled, the particular animations that occur are determined by the [Page]s associated with
  /// the routes that are undergoing a transition.
  ///
  /// See [TreeStateRoute.routePageBuilder] and [TreeStateRouter.defaultPageBuilder] for details on
  /// choosing a [Page] type.
  final bool enableTransitions;

  late final _routerDelegateConfig = TreeStateRouterDelegateConfig(
    routes,
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
  final BackButtonDispatcher? backButtonDispatcher = RootBackButtonDispatcher();

  /// The [RouteInformationParser] used by [TreeStateRouter].
  @override
  late final RouteInformationParser<TreeStateRouteInfo>? routeInformationParser =
      TreeStateRouteInformationParser(stateMachine.rootNode.key);

  /// The [RouteInformationProvider] used by [TreeStateRouter].
  @override
  late final routeInformationProvider = PlatformRouteInformationProvider(
    initialRouteInformation: RouteInformation(
      uri: Uri.parse(WidgetsBinding.instance.platformDispatcher.defaultRouteName),
    ),
  );
}
