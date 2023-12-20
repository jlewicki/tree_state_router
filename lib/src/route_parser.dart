import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/route_table.dart';
import 'package:tree_state_router/tree_state_router.dart';

/// TBD: Provides information about a route that is parsed from [RouteInformation] provided by the
/// system.
class TreeStateRouteMatches {
  /// The routes to displayed, based on route information provided by the platform. Routes are
  /// ordered in a descending fashion, such that the leaf routes is at the end of the list
  final List<StateRouteConfig> routes;
  TreeStateRouteMatches(this.routes);

  static final empty = TreeStateRouteMatches(List.unmodifiable([]));
}

/// TBD: A [RouteInformationParser] that can parse route information and determine the active states
/// of a [TreeStateMachine].
class TreeStateRouteInformationParser
    extends RouteInformationParser<TreeStateRouteMatches> {
  TreeStateRouteInformationParser(this.rootKey, this._routeTable);

  final StateKey rootKey;
  final RouteTable _routeTable;
  final Logger _log = Logger('TreeStateRouteInformationParser');

  @override
  Future<TreeStateRouteMatches> parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    var parsed = _routeTable.parseRouteInformation(routeInformation);
    if (parsed != null) {
      _log.fine(() =>
          'Parsed route information to ${parsed.routes.map((e) => e.stateKey).join(', ')}');
      return SynchronousFuture(parsed);
    }

    _log.fine('Route information was not parsed. Defaulting to empty matches');
    return SynchronousFuture(TreeStateRouteMatches.empty);
  }

  @override
  RouteInformation? restoreRouteInformation(
    TreeStateRouteMatches configuration,
  ) {
    return _routeTable.toRouteInformation(configuration.routes);
  }
}
