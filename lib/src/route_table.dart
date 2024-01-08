import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/build.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/routes/route_utility.dart';
import 'package:tree_state_router/tree_state_router.dart';

class RouteTable {
  RouteTable._(
    this._stateMachine,
    this._routePaths,
    this._routePathsByEndState,
  );

  factory RouteTable(
    TreeStateMachine stateMachine,
    List<StateRouteConfigProvider> routes,
  ) {
    // Map of all known routes
    var routesByState = Map.fromEntries(
      _withDescendants(routes).toList().map((r) => MapEntry(r.stateKey, r)),
    );

    // Complete set of full routeable paths. This is a naive data structure, but
    // it is good enough for now
    var rootNode = stateMachine.rootNode;
    var routePaths = rootNode
        .leaves()
        .map((leaf) => leaf
            .selfAndAncestors()
            .toList()
            .reversed
            .map((node) => routesByState[node.key])
            .where((r) => r != null)
            .cast<StateRouteConfig>())
        .where((routes) => routes.isNotEmpty)
        .map((routes) => TreeStateRoutePath(routes.toList()))
        .sorted(
          // Sort by number of route parameters, descending
          (r1, r2) => r2.parameters.length.compareTo(r1.parameters.length),
        )
        .toList();

    var routePathsByEndState =
        Map.fromEntries(routePaths.map((e) => MapEntry(e.end.stateKey, e)));

    return RouteTable._(
      stateMachine,
      routePaths,
      routePathsByEndState,
    );
  }

  final TreeStateMachine _stateMachine;
  final List<TreeStateRoutePath> _routePaths;
  final Map<StateKey, TreeStateRoutePath> _routePathsByEndState;

  RouteInformation? toRouteInformation(TreeStateRoutePath path) {
    assert(_stateMachine.currentState != null);
    var uriPath = path.isEmpty
        ? '/'
        : '/${path.generateUriPath(_stateMachine.currentState!)}';
    var uri = Uri.parse(uriPath);
    return RouteInformation(uri: uri);
  }

  TreeStateRoutePath routePathForTransition(
    Transition transition,
  ) {
    var routeForTarget = _routePathsByEndState[transition.to];
    return routeForTarget != null
        ? TreeStateRoutePath(routeForTarget.routes)
        : TreeStateRoutePath.empty;
  }

  TreeStateRoutePath? parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    var path = Uri.decodeFull(routeInformation.uri.path);
    if (path == '/') {
      return null;
    }

    return _routePaths.map((routePath) {
      var matched = routePath.matchUriPath(path);
      return matched != null
          ? TreeStateRoutePath(routePath.routes, matched)
          : null;
    }).firstWhere(
      (routePath) => routePath != null,
    );
  }

  /// Iterates through the routes and all of their descendants.
  static Iterable<StateRouteConfig> _withDescendants(
    List<StateRouteConfigProvider> routes,
  ) sync* {
    for (var route in routes) {
      yield* route.config.selfAndDescendants();
    }
  }
}
