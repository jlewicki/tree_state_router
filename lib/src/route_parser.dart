import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/route_table.dart';
import 'package:tree_state_router/tree_state_router.dart';

/// Provides information about a path of [StateRouteConfig]s that is parsed
/// from [RouteInformation] provided by the system.
class TreeStateRoutePath {
  TreeStateRoutePath(
    List<StateRouteConfig> routes, [
    Map<DataStateKey, Object> initialStateData = const {},
  ])  : routes = List.unmodifiable(routes),
        initialStateData = Map.unmodifiable(initialStateData);

  /// An empty [TreeStateRoutePath], containing no routes
  static final empty = TreeStateRoutePath(const []);

  /// The routes to displayed, based on route information provided by the
  /// platform. Routes are ordered in a descending fashion, such that the leaf
  /// route is at the end of the list
  final List<StateRouteConfig> routes;

  /// Unmodifiable map of initial data values for data state in the path, for
  /// use when initializing a state machine from a URI.
  final Map<DataStateKey, Object> initialStateData;

  /// Indicatates if this route path is empty. That is, if contains no routes.
  late bool isEmpty = routes.isEmpty;

  /// The complete path template for this route path, combining the
  /// [RoutePathConfig.pathTemplate] for all the routes in the path.
  late final pathTemplate = routes.map((r) => r.path.pathTemplate).join('/');

  /// The first route in the path.
  ///
  /// Throws an error if [isEmpty] is `true`.
  late final start = routes.first;

  /// The last route in the path.
  ///
  /// Throws an error if [isEmpty] is `true`.
  late final end = routes.last;

  /// The complete set of parameters in this route path, combining the
  /// [RoutePathConfig.parameters] for all the routes in the path.
  late final List<String> parameters =
      routes.expand((e) => e.path.parameters).toList();

  late final isDeepLinkable = routes.isNotEmpty && end.path.enableDeepLink;

  /// Generates a path appropriate for a URI representing all the routes in
  /// this route path.
  ///
  /// The [currentState] of the state machine is provided. This can be used to
  /// retrieve the current data value for data states in the path, if this data
  /// is needed when generating the path.
  String generateUriPath(CurrentState currentState) {
    return routes
        .map((r) => r.path.generateUriPath(switch (r.stateKey) {
              DataStateKey() =>
                currentState.dataValue(r.stateKey as DataStateKey),
              _ => null
            }))
        .join('/');
  }

  /// Attempts to match the [uriPath] against the routes in this route path.
  ///
  /// If the match succeeds, a map (possibly empty) containing initial data
  /// values for data states in the path is returned.  Otherwise, `null` is
  /// returned.
  Map<DataStateKey<dynamic>, Object>? matchUriPath(String uriPath) {
    var initialDataMap = <DataStateKey<dynamic>, Object>{};
    var restOfPath = uriPath;
    for (var r in routes) {
      var match = r.path.matchUriPath(restOfPath);
      if (match != null) {
        if (match.initialData != null) {
          assert(r.stateKey is DataStateKey);
          initialDataMap[r.stateKey as DataStateKey] = match.initialData!;
        }
        restOfPath = restOfPath.substring(match.pathMatch.length);
      }
    }

    return restOfPath.isEmpty ? initialDataMap : null;
  }
}

/// A [RouteInformationParser] that can parse route information into a
/// [TreeStateRoutePath] representing the active states of a [TreeStateMachine].
class TreeStateRouteInformationParser
    extends RouteInformationParser<TreeStateRoutePath> {
  TreeStateRouteInformationParser(this.rootKey, this._routeTable);

  final StateKey rootKey;
  final RouteTable _routeTable;
  final Logger _log = Logger('TreeStateRouteInformationParser');

  @override
  Future<TreeStateRoutePath> parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    _log.fine('Parsing route information: ${routeInformation.uri.path}');

    var parsed = _routeTable.parseRouteInformation(routeInformation);
    if (parsed != null) {
      _log.fine(() =>
          'Parsed route information to ${parsed.routes.map((e) => e.stateKey).join(', ')}');
      return SynchronousFuture(parsed);
    }

    _log.fine('Route information was not parsed. Defaulting to initial path');
    return SynchronousFuture(TreeStateRoutePath.empty);
  }

  @override
  RouteInformation? restoreRouteInformation(TreeStateRoutePath configuration) {
    _log.fine('Restoring route information.');
    return _routeTable.toRouteInformation(configuration);
  }
}
