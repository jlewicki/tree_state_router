import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';

class RouteTable {
  RouteTable._(
    this._rootNode,
    this._routePaths,
    this._routesByState,
    this._routePathsByStartState,
    this._routePathsByEndState,
  );

  factory RouteTable(
    RootNodeInfo rootNode,
    List<StateRouteConfigProvider> routes,
  ) {
    // Map of all known routes
    var routesByState = Map.fromEntries(
      _withDescendants(routes)
          .toList()
          .map((r) => MapEntry(r.route.stateKey, r.route)),
    );

    // Complete set of full routeable paths. This is a naive data structure, but it is good enough
    // for now
    var routePaths = rootNode
        .leaves()
        .map((leaf) => leaf
            .selfAndAncestors()
            .toList()
            .reversed
            .map((node) => routesByState[node.key])
            .where((r) => r != null && (r.path?.isNotEmpty ?? false))
            .cast<StateRouteConfig>())
        .where((routes) => routes.isNotEmpty)
        .map((routes) => TreeStateRoutePath(routes.toList()))
        .toList();

    var routePathsByStartState =
        routePaths.groupSetsBy((e) => e.start.stateKey);
    var routePathsByEndState =
        Map.fromEntries(routePaths.map((e) => MapEntry(e.end.stateKey, e)));

    return RouteTable._(
      rootNode,
      routePaths,
      routesByState,
      routePathsByStartState,
      routePathsByEndState,
    );
  }

  final RootNodeInfo _rootNode;
  final List<TreeStateRoutePath> _routePaths;
  final Map<StateKey, StateRouteConfig> _routesByState;
  final Map<StateKey, Set<TreeStateRoutePath>> _routePathsByStartState;
  final Map<StateKey, TreeStateRoutePath> _routePathsByEndState;

  RouteInformation? transitionRouteInformation(
    Transition transition,
  ) {
    return toRouteInformation(_routesForTransition(transition));
  }

  RouteInformation? toRouteInformation(Iterable<StateRouteConfig> routes) {
    var path = routes.map((e) {
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

  TreeStateRoutePath? transitionRouteMatches(
    Transition transition,
  ) {
    return TreeStateRoutePath(
      _routesForTransition(transition).toList(),
    );
  }

  TreeStateRoutePath? parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    var path = Uri.decodeFull(routeInformation.uri.path);
    path = path.startsWith('/') ? path.substring(1) : path;
    // TODO: this will not work with path parameters (like path: 'pages/:pageId')
    return _routePaths.firstWhereOrNull((r) => r.path == path);
  }

  Iterable<StateRouteConfig> _routesForTransition(
    Transition transition,
  ) {
    var routeForTarget = _routePathsByEndState[transition.to];
    assert(routeForTarget != null);
    return routeForTarget!.routes;
  }

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
