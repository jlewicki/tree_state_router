import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';

class TreeStateRouteInfo {
  final StateKey currentState;
  TreeStateRouteInfo(this.currentState);
}

class TreeStateRouteInformationParser extends RouteInformationParser<TreeStateRouteInfo> {
  TreeStateRouteInformationParser(this.rootKey);

  final StateKey rootKey;

  @override
  Future<TreeStateRouteInfo> parseRouteInformation(RouteInformation routeInformation) {
    if (routeInformation.uri.path == '/') {
      return SynchronousFuture(TreeStateRouteInfo(rootKey));
    }
    throw UnimplementedError('Route parsing is not yet supported.');
  }
}
