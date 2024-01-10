import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/routes/route_utility.dart';
import 'package:tree_state_router/tree_state_router.dart';

class RouteTable {
  RouteTable._(
    this._stateMachine,
    this._routePaths,
    this._linkableRoutePaths,
    this._routePathsByEndState,
  );

  factory RouteTable(
    TreeStateMachine stateMachine,
    List<StateRouteInfo> routes,
  ) {
    var linkableRoutePaths = routes
        .expand((e) => e.selfAndDescendants())
        .where((e) => e.path.enableDeepLink)
        .map((e) =>
            TreeStateRoutePath(e.selfAndAncestors().toList().reversed.toList()))
        .sorted(sortByParameterCountDescending)
        .toList();

    var allRoutePaths = routes
        .expand((e) => e.leaves())
        .map((e) =>
            TreeStateRoutePath(e.selfAndAncestors().toList().reversed.toList()))
        .sorted(sortByParameterCountDescending)
        .toList();

    var routePathsByEndState =
        Map.fromEntries(allRoutePaths.map((e) => MapEntry(e.end.stateKey, e)));

    return RouteTable._(
      stateMachine,
      allRoutePaths,
      linkableRoutePaths,
      routePathsByEndState,
    );
  }

  final TreeStateMachine _stateMachine;
  final List<TreeStateRoutePath> _routePaths;
  final List<TreeStateRoutePath> _linkableRoutePaths;
  final Map<StateKey, TreeStateRoutePath> _routePathsByEndState;

  RouteInformation? toRouteInformation(TreeStateRoutePath path) {
    var uriPath =
        path.isEmpty ? '/' : '/${path.generateUriPath(_getDataValue)}';
    var uri = Uri.parse(uriPath);
    return RouteInformation(uri: uri);
  }

  TreeStateRoutePath routePathForTransition(
    Transition transition,
  ) {
    var routeForTarget = _routePathsByEndState[transition.to];
    return routeForTarget ?? TreeStateRoutePath.empty;
  }

  TreeStateRoutePath? parseRouteInformation(
    RouteInformation routeInformation, {
    required bool linkableRoutes,
  }) {
    var path = Uri.decodeFull(routeInformation.uri.path);
    if (path == '/') {
      return null;
    }

    var routePaths = linkableRoutes ? _linkableRoutePaths : _routePaths;
    return routePaths.map((routePath) {
      var matched = routePath.matchUriPath(path);
      return matched != null
          ? TreeStateRoutePath(routePath.routes, matched)
          : null;
    }).firstWhereOrNull(
      (routePath) => routePath != null,
    );
  }

  dynamic _getDataValue(DataStateKey stateKey) {
    assert(_stateMachine.currentState != null);
    return _stateMachine.currentState!.dataValue(stateKey);
  }
}

int sortByParameterCountDescending(
  TreeStateRoutePath p1,
  TreeStateRoutePath p2,
) {
  return p2.parameters.length.compareTo(p1.parameters.length);
}
