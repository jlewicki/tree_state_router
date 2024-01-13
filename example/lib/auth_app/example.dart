import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'package:tree_state_router_examples/auth_app/auth_state_tree.dart';
import 'package:tree_state_router_examples/auth_app/pages.dart';
import 'package:tree_state_router_examples/auth_app/services/auth_service.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

//
// This example demonstrates accessing and updating state and ancestor state data in a route for
// a leaf state.
//
// Each route displays all relevant state data belonging to active states, whether it belongs to the
// state for the route, or one of its ancestor states.
//
void main() {
  usePathUrlStrategy();
  _initLogging();
  runApp(const MainApp());
}

var authService = AppAuthService();

final router = TreeStateRouter.platformRouting(
  defaultScaffolding: (_, pageContent) => Scaffold(
    body: pageContent,
  ),
  stateTree: authStateTree(authService),
  routes: [
    DataStateRoute<LoginData>(
      AuthStates.login,
      routeBuilder: loginPage,
      path: DataRoutePath('login'),
    ),
    DataStateRoute<AuthenticatedData>(
      AuthStates.authenticated,
      routeBuilder: authenticatedPage,
      path: DataRoutePath('user/home', enableDeepLink: true),
    )
  ],
);

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
    );
  }
}

void _initLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    log('${record.level.name}: ${record.loggerName}: ${record.time}: '
        '${record.message} ${record.error?.toString() ?? ''}');
  });
}
