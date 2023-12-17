import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';

/// TBD: Provides information about a route that is parsed from [RouteInformation] provided by the
/// system.
class TreeStateRouteInfo {
  final StateKey currentState;
  TreeStateRouteInfo(this.currentState);
}

/// TBD: A [RouteInformationParser] that can parse route information and determine the active states
/// of a [TreeStateMachine].
class TreeStateRouteInformationParser
    extends RouteInformationParser<TreeStateRouteInfo> {
  TreeStateRouteInformationParser(this.rootKey);

  final StateKey rootKey;

  @override
  Future<TreeStateRouteInfo> parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    if (routeInformation.uri.path == '/') {
      return SynchronousFuture(TreeStateRouteInfo(rootKey));
    }
    throw UnimplementedError('Route parsing is not yet supported.');
  }
}
