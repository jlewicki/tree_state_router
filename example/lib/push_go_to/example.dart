import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'state_tree.dart';
import 'pages.dart';

//
// This example illustrates the use of the pushGoTo extension method to simulate
// a state transition pushing on to the navigation stack, instead of replacing
//
void main() {
  _initLogging();
  runApp(const MainApp());
}

final router = TreeStateRouter.platformRouting(
  stateTree: pushGoToStateTree(),
  enableDeveloperLogging: true,
  routes: [
    StateRoute(
      States.state1,
      routeBuilder: (ctx, stateCtx) => statePage(ctx, stateCtx, 'State 1'),
    ),
    StateRoute(
      States.state2,
      routeBuilder: (ctx, stateCtx) => statePage(ctx, stateCtx, 'State 2'),
    ),
    StateRoute(
      States.state3,
      routeBuilder: (ctx, stateCtx) => statePage(ctx, stateCtx, 'State 3'),
    ),
    StateRoute(
      States.state4,
      routeBuilder: (ctx, stateCtx) => statePage(ctx, stateCtx, 'State 4'),
    ),
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
  hierarchicalLoggingEnabled = true;
}
