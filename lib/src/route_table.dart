import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';

class _RoutePath {
  _RoutePath(this.path, this.routes);
  final String path;
  final List<StateRouteConfig> routes;
}

class RouteTable {
  RouteTable._(
    this._linkableRoutes,
    this._routePaths,
  );

  factory RouteTable(
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
    return RouteTable._(linkableRouteMap, routePaths);
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
