import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/route_table.dart';
import 'package:tree_state_router/tree_state_router.dart';

/// TBD: Provides information about a route that is parsed from [RouteInformation] provided by the
/// system.

class TreeStateRoutePath {
  TreeStateRoutePath(List<StateRouteConfig> routes)
      : routes = List.unmodifiable(routes);

  static final empty = TreeStateRoutePath(const []);

  /// The routes to displayed, based on route information provided by the platform. Routes are
  /// ordered in a descending fashion, such that the leaf route is at the end of the list
  final List<StateRouteConfig> routes;

  late bool isEmpty = routes.isEmpty;

  late final path = routes.map((r) => r.path.path).join('/');

  /// The first route in the path.
  ///
  /// Throws an error if [isEmpty] is `true`.
  late final start = routes.first;

  /// The last route in the path.
  ///
  /// Throws an error if [isEmpty] is `true`.
  late final end = routes.last;

  late final isDeepLinkable = routes.isNotEmpty && end.path.enableDeepLink;
}

/// TBD: A [RouteInformationParser] that can parse route information and determine the active states
/// of a [TreeStateMachine].
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
    _log.fine('Parsing route inforation: ${routeInformation.uri.path}');

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
    return _routeTable.toRouteInformation(configuration);
  }
}
