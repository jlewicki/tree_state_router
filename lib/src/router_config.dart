import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/route_provider.dart';
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
class TreeStateRouter implements RouterConfig<TreeStateRouteMatches> {
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

  late final _routeTabke = DeepLinkRouteTable(stateMachine.rootNode, routes);

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
    routeTable: _routeTabke,
  );

  /// The [RootBackButtonDispatcher] used by [TreeStateRouter].
  @override
  final backButtonDispatcher = RootBackButtonDispatcher();

  /// The [RouteInformationParser] used by [TreeStateRouter].
  @override
  late final routeInformationParser = TreeStateRouteInformationParser(
    stateMachine.rootNode.key,
    _routeTabke,
  );

  /// The [RouteInformationProvider] used by [TreeStateRouter].
  @override
  late final routeInformationProvider = PlatformRouteInformationProvider(
      initialRouteInformation: RouteInformation(
    uri: Uri.parse(
      WidgetsBinding.instance.platformDispatcher.defaultRouteName,
    ),
  ));
  // late final routeInformationProvider = TreeStateRouteInformationProvider(
  //   routes,
  //   stateMachine,
  //   _deepLinkRouteTable,
  // );
}

class _RoutePath {
  _RoutePath(this.path, this.routes);
  final String path;
  final List<StateRouteConfig> routes;
}

class DeepLinkRouteTable {
  DeepLinkRouteTable._(
    this._linkableRoutes,
    this._routePaths,
  );

  factory DeepLinkRouteTable(
    RootNodeInfo rootNode,
    List<StateRouteConfigProvider> routes,
  ) {
    var linkableRoutes = _withDescendants(routes)
        .where((r) => r.route.path?.isNotEmpty ?? false)
        .toList();

    var linkableRouteMap = Map.fromEntries(
      linkableRoutes.map((r) => MapEntry(r.route.stateKey, r.route)),
    );

    // Complete set of full routeable paths. This is a naive data structure, but it is good enough
    // for now
    var routePaths = rootNode
        .leaves()
        .map((leaf) => leaf
            .selfAndAncestors()
            .toList()
            .reversed
            .map((node) => linkableRouteMap[node.key])
            .where((r) => r != null && (r.path?.isNotEmpty ?? false))
            .cast<StateRouteConfig>())
        .where((routes) => routes.isNotEmpty)
        .map((routes) => _RoutePath(
              routes.map((r) => r.path!).join('/'),
              routes.toList(),
            ))
        .toList();
    return DeepLinkRouteTable._(linkableRouteMap, routePaths);
  }

  final Map<StateKey, StateRouteConfig> _linkableRoutes;
  final List<_RoutePath> _routePaths;

  RouteInformation? transitionRouteInformation(
    Transition transition,
  ) {
    return toRouteInformation(_linkableRoutesForTransition(transition));
  }

  TreeStateRouteMatches? transitionRouteMatches(
    Transition transition,
  ) {
    return TreeStateRouteMatches(
      _linkableRoutesForTransition(transition).toList(),
    );
  }

  RouteInformation? toRouteInformation(
    Iterable<StateRouteConfig> linkableRoutes,
  ) {
    var path = linkableRoutes.map((e) {
      assert(e.path != null);
      return e.path!;
    }).join('/');

    if (path.isEmpty) {
      return null;
    }

    path = '/$path';
    var uri = Uri.parse(path);
    return RouteInformation(uri: uri);
  }

  TreeStateRouteMatches? parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    var path = routeInformation.uri.path;
    path = path.startsWith('/') ? path.substring(1) : path;
    for (var routePath in _routePaths) {
      if (routePath.path == path) {
        // TODO: this will not work with path parameters (like path: 'pages/:pageId')
        return TreeStateRouteMatches(routePath.routes);
      }
    }
    return null;
  }

  Iterable<StateRouteConfig> _linkableRoutesForTransition(
    Transition transition,
  ) =>
      // TODO: We need to look up routes by ancestor path for target state, not the entry states
      transition.entryPath
          .map(_getDeepLinkRoute)
          .where((r) => r != null)
          .cast<StateRouteConfig>();

  StateRouteConfig? _getDeepLinkRoute(StateKey stateKey) =>
      _linkableRoutes[stateKey];

  /// Iterates through the routes and all of their descendants.
  static Iterable<_RouteWithDepth> _withDescendants(
    List<StateRouteConfigProvider> routes,
  ) sync* {
    for (var route in routes) {
      yield* _selfAndDescendantsWithDepth(route.config);
    }
  }

  static Iterable<_RouteWithDepth> _selfAndDescendantsWithDepth(
    StateRouteConfig route,
  ) sync* {
    Iterable<_RouteWithDepth> selfAndDescendants_(
      StateRouteConfig route,
      int depth,
    ) sync* {
      yield _RouteWithDepth(route, depth);
      for (var child in route.childRoutes) {
        yield* selfAndDescendants_(child, depth + 1);
      }
    }

    yield* selfAndDescendants_(route, 0);
  }
}

class _RouteWithDepth {
  _RouteWithDepth(this.route, this.depth);
  final StateRouteConfig route;
  final int depth;
}

extension TreeNodeInfoNavExtensions on TreeNodeInfo {
  Iterable<TreeNodeInfo> ancestors() sync* {
    TreeNodeInfo? parent(TreeNodeInfo node) {
      return switch (node) {
        LeafNodeInfo(parent: var p) => p,
        InteriorNodeInfo(parent: var p) => p,
        _ => null
      };
    }

    var nextAncestor = parent(this);
    while (nextAncestor != null) {
      yield nextAncestor;
      nextAncestor = parent(nextAncestor);
    }
  }

  Iterable<TreeNodeInfo> selfAndAncestors() sync* {
    yield this;
    yield* ancestors();
  }

  Iterable<LeafNodeInfo> leaves() {
    return selfAndDescendants().whereType<LeafNodeInfo>();
  }
}



// static int _compareByDepth(_RouteWithDepth r1, _RouteWithDepth r2) =>
//       r1.depth - r2.depth;
//   static int _compareByPath(_RouteWithDepth r1, _RouteWithDepth r2) =>
//       r1.route.path!.compareTo(r2.route.path!);
