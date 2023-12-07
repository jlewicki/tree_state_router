import 'package:flutter/widgets.dart';
import 'package:tree_state_router/src/parser.dart';

class TreeStateRouter implements RouterConfig<TreeStateRouteInfo> {
  TreeStateRouter();

  @override
  BackButtonDispatcher? get backButtonDispatcher => throw UnimplementedError();

  @override
  RouteInformationParser<TreeStateRouteInfo>? get routeInformationParser =>
      throw UnimplementedError();

  @override
  RouteInformationProvider? get routeInformationProvider => throw UnimplementedError();

  @override
  RouterDelegate<TreeStateRouteInfo> get routerDelegate => throw UnimplementedError();
}
