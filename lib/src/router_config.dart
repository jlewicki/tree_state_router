import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/pages/pages.dart';
import 'package:tree_state_router/src/parser.dart';
import 'package:tree_state_router/src/router_delegate.dart';
import 'package:tree_state_router/src/routes.dart';

typedef DefaultLayoutBuilder = Widget Function(PageBuildFor pageKey, Widget pageContent);

typedef DefaultPageBuilder = Page<void> Function(PageBuildFor pageKey, Widget pageContent);

///
class TreeStateRouterConfig implements RouterConfig<TreeStateRouteInfo> {
  TreeStateRouterConfig({
    required this.stateMachine,
    required this.routes,
    this.defaultLayout,
    this.defaultPageBuilder,
  });

  /// The list of routes that can be materialized by this router.
  final List<TreeStateRoute> routes;

  /// If provided, a function can wrap the widget that displays a [TreeStateRoute] with additional
  /// layout or scaffolding.
  ///
  /// The function is provided a, and the page content that displays the route, and should return
  /// the widget representing the final page content for the route.
  final DefaultLayoutBuilder? defaultLayout;

  final DefaultPageBuilder? defaultPageBuilder;

  final TreeStateMachine stateMachine;

  @override
  late final routerDelegate = TreeStateRouterDelegate(
    stateMachine: stateMachine,
    routerConfig: this,
  );

  @override
  final BackButtonDispatcher? backButtonDispatcher = RootBackButtonDispatcher();

  @override
  late final RouteInformationParser<TreeStateRouteInfo>? routeInformationParser =
      TreeStateRouteInformationParser(stateMachine.rootNode.key);

  @override
  // RouteInformationProvider? get routeInformationProvider => null;
  late final routeInformationProvider = PlatformRouteInformationProvider(
    initialRouteInformation: RouteInformation(
      uri: Uri.parse(WidgetsBinding.instance.platformDispatcher.defaultRouteName),
    ),
  );
}
