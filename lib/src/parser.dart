import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';

class TreeStateRouteInfo {
  final StateKey currentState;
  TreeStateRouteInfo(this.currentState);
}

class StateTreeRouteInformationParser extends RouteInformationParser<TreeStateRouteInfo> {
  @override
  Future<TreeStateRouteInfo> parseRouteInformation(RouteInformation routeInformation) {
    throw UnimplementedError('Route parsing is not yet supported.');
  }
}
