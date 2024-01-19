import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/route_table.dart';
import 'package:tree_state_router/tree_state_router.dart';

/// Provides information about a path of [StateRouteInfo]s that is parsed
/// from [RouteInformation] provided by the system.
class TreeStateRoutePath {
  TreeStateRoutePath(
    List<StateRouteInfo> routes, {
    this.platformUri,
    Map<DataStateKey, Object> initialStateData = const {},
    this.isPush = false,
  })  : routes = List.unmodifiable(routes),
        initialStateData = Map.unmodifiable(initialStateData);

  /// An empty [TreeStateRoutePath], containing no routes
  static final empty = TreeStateRoutePath(const []);

  /// Creates a copy of this route path, but with [isPush] set to `true`.
  TreeStateRoutePath asPush(bool isPush) {
    return isPush != this.isPush
        ? TreeStateRoutePath(routes, isPush: isPush)
        : this;
  }

  TreeStateRoutePath withUri(Uri? platformUri) {
    return platformUri != null
        ? TreeStateRoutePath(routes, platformUri: platformUri)
        : this;
  }

  /// The routes to displayed, based on route information provided by the
  /// platform. Routes are ordered in a descending fashion, such that the leaf
  /// route is at the end of the list
  final List<StateRouteInfo> routes;

  /// Unmodifiable map of initial data values for data state in the path, for
  /// use when initializing a state machine when following a deep link.
  final Map<DataStateKey, Object> initialStateData;

  /// The URI provided by the platform when following a deep link.
  final Uri? platformUri;

  /// Indicates if this route path is empty. That is, if contains no routes.
  late bool isEmpty = routes.isEmpty;

  /// The complete path template for this route path, combining the
  /// [RoutePathInfo.pathTemplate] for all the routes in the path.
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
  /// [RoutePathInfo.parameters] for all the routes in the path.
  late final List<String> parameters =
      routes.expand((e) => e.path.parameters).toList();

  /// Indicates if the leaf state for this route path is deep-linkable.
  late final isDeepLinkable = routes.isNotEmpty && end.path.enableDeepLink;

  /// Indicates if this route path was sourced from a 'push' transition. That
  /// is, one that should simulate [Navigator.push] from an end user
  /// perspective.
  final bool isPush;

  /// Generates a path appropriate for a URI representing all the routes in
  /// this route path.
  ///
  /// A [getDataValue] function must be provided, which is called when
  /// generating URI path segments for parameterized [RoutePathInfo] in the
  /// route path.  he function must return the current state data value for the
  /// provided state key.
  String generateUriPath(
    dynamic Function(DataStateKey<dynamic>) getDataValue,
  ) {
    return routes
        .map((r) => r.path.generateUriPath(switch (r.stateKey) {
              DataStateKey() when r.path.parameters.isNotEmpty =>
                getDataValue(r.stateKey as DataStateKey),
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
    var numMatches = 0;
    for (var r in routes) {
      var match = r.path.matchUriPath(restOfPath);
      if (match != null) {
        numMatches++;
        if (match.initialData != null) {
          assert(r.stateKey is DataStateKey);
          initialDataMap[r.stateKey as DataStateKey] = match.initialData!;
        }
        restOfPath = restOfPath.substring(match.pathMatch.length);
        if (restOfPath.isEmpty) break;
      }
    }

    return restOfPath.isEmpty && numMatches == routes.length
        ? initialDataMap
        : null;
  }
}

/// A [RouteInformationParser] that can parse route information into a
/// [TreeStateRoutePath] representing the active states of a [TreeStateMachine].
class TreeStateRouteInformationParser
    extends RouteInformationParser<TreeStateRoutePath> {
  TreeStateRouteInformationParser(this.rootKey, this.routeTable);

  final StateKey rootKey;
  final RouteTable routeTable;
  final Logger _log = Logger('$rootLoggerName.RouteParser');

  @override
  Future<TreeStateRoutePath> parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    _log.fine('Parsing route information: ${routeInformation.uri.toString()}');

    var parsed = routeTable.parseRouteInformation(
      routeInformation,
      linkableRoutes: true,
    );
    if (parsed != null) {
      _log.fine(() => 'Parsed route information to deep linkable route path '
          '${parsed.routes.map((e) => e.stateKey).join(', ')}');
      return SynchronousFuture(parsed);
    }

    _log.fine('Route information was not parsed. Defaulting to initial path');
    return SynchronousFuture(TreeStateRoutePath.empty);
  }

  @override
  RouteInformation? restoreRouteInformation(TreeStateRoutePath configuration) {
    if (configuration.isPush) {
      _log.fine('Restoring route information for push route path. '
          'Reporting null to platform, URI will not change.');
      return null;
    }
    _log.fine('Restoring route information.');
    return routeTable.toRouteInformation(configuration);
  }
}
