import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_machine/build.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/route_provider.dart';
import 'package:tree_state_router/src/route_table.dart';
import 'package:tree_state_router/src/routes/route_utility.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'package:tree_state_router/src/router_delegate.dart';

/// A function that can adorn the content of a route page, adding common layout
/// or scaffolding.
///
/// The function is provided a [buildFor] indicating the reason the page is
/// being built, and the [pageContent] to display in the page.
typedef DefaultScaffoldingBuilder = Widget Function(
  PageBuildFor buildFor,
  Widget pageContent,
);

/// A function that can create a [Page] to display the content of a route.
///
/// The function is provided a [buildFor] indicating the reason the page is
/// being built, and the [pageContent] to display in the page.
///
/// The function can return `null` if the application does not require
/// specialized page under certain conditions, in which case the router will use
/// a default [Page].
typedef DefaultPageBuilder = Page<void>? Function(
  PageBuildFor buildFor,
  Widget pageContent,
);

/// Routing information that describes how to display states in a
/// [TreeStateMachine], and triggers routing navigation in response to state
/// transitions within the state machine.
class TreeStateRouter implements RouterConfig<TreeStateRoutePath> {
  TreeStateRouter._({
    required this.stateMachine,
    required this.routes,
    this.defaultScaffolding,
    this.defaultPageBuilder,
    this.enableTransitions = true,
    this.enablePlatformRouting = false,
  }) : assert((() {
          routes.fold(<StateKey>{}, (keys, route) {
            if (keys.contains(route.stateKey)) {
              throw AssertionError("There is more than one route for state "
                  "'${route.stateKey}' defined");
            }
            keys.add(route.stateKey);
            return keys;
          });
          return true;
        }()));

  /// Constructs a [TreeStateRouter].
  ///
  /// The router will not have any integration with the Navigator 2.0 APIs, and
  /// as a result will not sync route information with the underlying platform.
  /// If running in a web browser, there will not URL changes or history entries
  /// in response to route changes.
  factory TreeStateRouter({
    TreeStateMachine? stateMachine,
    StateTreeBuildProvider? stateTree,
    required List<StateRouteConfigProvider> routes,
    DefaultScaffoldingBuilder? defaultScaffolding,
    DefaultPageBuilder? defaultPageBuilder,
    bool enableTransitions = true,
  }) {
    assert(stateMachine != null || stateTree != null,
        "Either stateMachine or stateTree must be provided ");
    assert(!(stateMachine != null && stateTree != null),
        "Only one of stateMachine or stateTree can be provided ");
    return TreeStateRouter._(
      stateMachine: stateMachine ?? TreeStateMachine(stateTree!),
      routes: routes.map((e) => e.createConfig(null)).toList(),
      defaultScaffolding: defaultScaffolding,
      defaultPageBuilder: defaultPageBuilder,
      enableTransitions: enableTransitions,
      enablePlatformRouting: false,
    );
  }

  /// Constructs a [TreeStateRouter] that integrates with Navigator 2.0 APIs.
  ///
  /// By default, the router will sync route path information with the underying
  /// platform, but without any history support. If running in a web browser,
  /// the browser URL will update, but no history entries updated.
  factory TreeStateRouter.platformRouting({
    required StateTreeBuildProvider stateTree,
    required List<StateRouteConfigProvider> routes,
    DefaultScaffoldingBuilder? defaultScaffolding,
    DefaultPageBuilder? defaultPageBuilder,
    bool enableTransitions = true,
  }) {
    var routeConfigs = routes.map((e) => e.createConfig(null)).toList();
    // Find data routes that have route parameters. Theses routes will have
    // tree state filters installed that can initialize state data
    var dataRoutesWithParams = Map.fromEntries(routeConfigs
        .expand((r) => r.selfAndDescendants())
        .where((r) =>
            r.path is DataRoutePath &&
            (r.path as DataRoutePath).initialData != null)
        .map((r) => MapEntry(r.stateKey, r.path as DataRoutePath)));

    // Extend state tree with routing filters
    var builder = StateTreeBuilder(
      stateTree,
      createBuildContext: () => TreeBuildContext(
        extendNodes: (b) {
          if (b.nodeBuildInfo is RootNodeInfo) {
            b.filter(_createRoutingFilter());
          }
          var dataRoute = dataRoutesWithParams[b.nodeBuildInfo.key];
          if (dataRoute != null) {
            b.filter(dataRoute.createFilter());
          }
        },
      ),
    );

    return TreeStateRouter._(
      stateMachine: TreeStateMachine.withBuilder(builder),
      routes: routeConfigs,
      defaultScaffolding: defaultScaffolding,
      defaultPageBuilder: defaultPageBuilder,
      enableTransitions: enableTransitions,
      enablePlatformRouting: true,
    );
  }

  /// The state machine providing the tree states that are routed by this
  /// [TreeStateRouter].
  final TreeStateMachine stateMachine;

  /// The list of routes that can be materialized by this router.  Each route
  /// should correspond to a state in the [stateMachine].
  final List<StateRouteConfig> routes;

  /// Indictes if the router integrates with the platform routing engine, such
  /// that web browser URLs are updated in response to route changes.
  final bool enablePlatformRouting;

  /// {@template TreeStateRouter.defaultScaffolding}
  /// A function that can adorn the content of a route page, adding common
  /// layout or scaffolding.
  ///
  /// The function is provided a `buildFor` indicating the reason the page is
  /// being built, and the `pageContent` to display in the page.
  /// {@endtemplate}
  ///
  /// For example, this can be used to wrap the content of each page of a tree
  /// state router in a Material Scaffold widget:
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
  /// The function is provided a `buildFor` indicating the reason the page is
  /// being built, and the `pageContent` to display in the page.
  /// {@endtemplate}
  final DefaultPageBuilder? defaultPageBuilder;

  /// {@template TreeStateRouter.enableTransitions}
  /// Indicates if page transitions within the router should be animated.
  ///
  /// If enabled, the particular animations that occur are determined by the
  /// [Page]s associated with the routes that are undergoing a transition.
  ///
  /// See [StateRoute.routePageBuilder] and [TreeStateRouter.defaultPageBuilder]
  /// for details on choosing a [Page] type.
  /// {@endtemplate}
  final bool enableTransitions;

  late final _routeTable = RouteTable(stateMachine, routes);

  late final _routerDelegateConfig = TreeStateRouterDelegateConfig(
    routes.toList(),
    defaultPageBuilder: defaultPageBuilder,
    defaultScaffolding: defaultScaffolding,
    enableTransitions: enableTransitions,
    enablePlatformRouting: enablePlatformRouting,
  );

  /// The [RouterDelegate] used by [TreeStateRouter].
  @override
  late final routerDelegate = TreeStateRouterDelegate(
    config: _routerDelegateConfig,
    stateMachine: stateMachine,
    routeTable: _routeTable,
  );

  /// The [RootBackButtonDispatcher] used by [TreeStateRouter].
  @override
  final backButtonDispatcher = null; //RootBackButtonDispatcher();

  /// The [RouteInformationParser] used by [TreeStateRouter].
  @override
  late final routeInformationParser = enablePlatformRouting
      ? TreeStateRouteInformationParser(
          stateMachine.rootNode.key,
          _routeTable,
        )
      : null;

  /// The [RouteInformationProvider] used by [TreeStateRouter].
  @override
  late final routeInformationProvider = enablePlatformRouting
      ? TreeStateRouteInformationProvider(
          initialRouteInformation: RouteInformation(
            uri: Uri.parse(
              WidgetsBinding.instance.platformDispatcher.defaultRouteName,
            ),
          ),
          historyMode: SystemNavigatorHistoryMode.singleEntry,
        )
      : null;
}

class GoToDeepLink {
  GoToDeepLink(this.target, {this.initialStateData = const {}});
  final StateKey target;
  final Map<DataStateKey<dynamic>, Object> initialStateData;
}

class _InitialDataPayload {
  _InitialDataPayload(this.initialStateData);
  final Map<DataStateKey<dynamic>, dynamic> initialStateData;
}

TreeStateFilter _createRoutingFilter([Logger? log]) {
  var filterName = 'tree_state_router.DeepLinkFilter';
  var log_ = log ?? Logger(filterName);
  return TreeStateFilter(
    name: filterName,
    onMessage: (msgCtx, next) {
      if (msgCtx.message
          case GoToDeepLink(target: var t, initialStateData: var d)) {
        log_.fine("Deep link routing to state '$t'");
        return SynchronousFuture(msgCtx.goTo(
          t,
          payload: _InitialDataPayload(d),
          reenterTarget: true,
        ));
      }
      return next();
    },
  );
}

class InitializeStateDataFilter<D> extends TreeStateFilter {
  InitializeStateDataFilter({Logger? log})
      : _log = log ?? Logger(_filterName),
        super(name: _filterName);

  final Logger _log;
  static const _filterName = 'tree_state_router.InitialDataFilter';

  @override
  Future<void> onEnter(TransitionContext ctx, Future<void> Function() next) {
    if (ctx.payload case _InitialDataPayload(initialStateData: var d)) {
      if (ctx.handlingState is DataStateKey<D>) {
        var dataKey = ctx.handlingState as DataStateKey<D>;
        var initData = d[dataKey];
        if (initData != null) {
          assert(initData is D);
          _log.fine("Setting initial data for data state '$dataKey'");
          ctx.data(dataKey).update((_) => initData as D);
        }
      }
    }
    return next();
  }
}
