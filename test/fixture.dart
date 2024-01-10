// ignore_for_file: constant_identifier_names

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';
import 'package:tree_state_machine/build.dart';
import 'package:tree_state_machine/delegate_builders.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/routes/route_utility.dart';
import 'package:tree_state_router/tree_state_router.dart';

class States {
  static const state_r = StateKey('r');
  static const state_r_1 = StateKey('r_1');
  static const state_r_2 = StateKey('r_2');
  static const state_r_2_1 = StateKey('r_2_1');
  static const state_r_2_2 = StateKey('r_2_2');
}

class DataStates {
  static const state_r = DataStateKey<String>('r');
  static const state_r_1 = DataStateKey<String>('r_1');
  static const state_r_2 = DataStateKey<String>('r_2');
  static const state_r_2_1 = DataStateKey<String>('r_2_1');
  static const state_r_2_2 = DataStateKey<String>('r_2_2');
}

StateTree dataStateTree() {
  return StateTree.dataRoot(
    DataStates.state_r,
    InitialData(() => 'r'),
    InitialChild(DataStates.state_r_2),
    childStates: [
      DataState(DataStates.state_r_1, InitialData(() => 'r_1')),
      DataState.composite(
        DataStates.state_r_2,
        InitialData(() => 'r_2'),
        InitialChild(DataStates.state_r_2_1),
        childStates: [
          DataState(DataStates.state_r_2_1, InitialData(() => 'r_2_1')),
          DataState(DataStates.state_r_2_2, InitialData(() => 'r_2_2')),
        ],
      ),
    ],
  );
}

TreeStateRouter dataRouter(
  TreeStateMachine stateMachine, {
  bool parameterize = false,
}) {
  return TreeStateRouter(
    stateMachine: stateMachine,
    routes: [
      DataStateRoute<String>.shell(
        DataStates.state_r,
        routeBuilder: emptyShellDataRouteBuilder,
        path: parameterize
            ? DataRoutePath.withParams(
                'r/:val',
                pathArgs: (data) => {'val': data},
              )
            : DataRoutePath('r'),
        routes: [
          DataStateRoute<String>.shell(
            DataStates.state_r_2,
            routeBuilder: emptyShellDataRouteBuilder,
            path: parameterize
                ? DataRoutePath.withParams(
                    '2/:val',
                    enableDeepLink: true,
                    pathArgs: (data) => {'val': data},
                    initialData: (pathArgs) => pathArgs['val']!,
                  )
                : DataRoutePath('2', enableDeepLink: true),
            routes: [
              DataStateRoute<String>(
                DataStates.state_r_2_1,
                routeBuilder: emptyDataRouteBuilder,
                path: parameterize
                    ? DataRoutePath.withParams(
                        '1/:val',
                        pathArgs: (data) => {'val': data},
                      )
                    : DataRoutePath('1'),
              ),
              DataStateRoute<String>(
                DataStates.state_r_2_2,
                routeBuilder: emptyDataRouteBuilder,
                path: parameterize
                    ? DataRoutePath.withParams(
                        '2/:val',
                        enableDeepLink: true,
                        pathArgs: (data) => {'val': data},
                        initialData: (pathArgs) => pathArgs['val']!,
                      )
                    : DataRoutePath('2', enableDeepLink: true),
              )
            ],
          ),
        ],
      )
    ],
  );
}

Widget emptyRouteBuilder(
  BuildContext context,
  StateRoutingContext stateContext,
) =>
    const Placeholder();

Widget emptyShellRouteBuilder(
  BuildContext context,
  StateRoutingContext stateContext,
  Widget nestedRouter,
) =>
    const Placeholder();

Widget emptyDataRouteBuilder<D>(
  BuildContext context,
  StateRoutingContext stateContext,
  D data,
) =>
    const Placeholder();

Widget emptyShellDataRouteBuilder<D>(
  BuildContext context,
  StateRoutingContext stateContext,
  Widget nestedRouter,
  D data,
) =>
    const Placeholder();

void expectConfig(
  List<StateRouteConfig> configs,
  StateKey key,
  StateKey? parent,
  List<StateKey> children,
) {
  var config = configs.firstWhereOrNull((e) => e.stateKey == key);
  expect(config, isNotNull);
  expect(config!.parentRoute?.stateKey, parent);
  expect(
    const SetEquality<StateKey>().equals(
      config.childRoutes.map((e) => e.stateKey).toSet(),
      children.toSet(),
    ),
    isTrue,
  );
}

TreeStateRoutePath toRoutePath(StateRouteConfig route) {
  return TreeStateRoutePath(
    route.selfAndAncestors().toList().reversed.toList(),
  );
}
