// ignore_for_file: constant_identifier_names

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/routes/route_utility.dart';
import 'package:tree_state_router/tree_state_router.dart';

const state_r = StateKey('r');
const state_r_1 = StateKey('r_1');
const state_r_2 = StateKey('r_2');
const state_r_2_1 = StateKey('r_2_1');
const state_r_2_2 = StateKey('r_2_2');

void main() {
  group('StateRoute', () {
    group('createConfig', () {
      test('should create a route tree for a single route', () {
        var rootRoute = StateRoute(
          state_r,
          routeBuilder: emptyRouteBuilder,
        );
        var rootConfig = rootRoute.createConfig(null);
        expect(rootConfig.stateKey, state_r);
        expect(rootConfig.parentRoute, isNull);
        expect(rootConfig.childRoutes, isEmpty);
      });

      test('should create a route tree', () {
        var rootRoute = StateRoute.shell(
          state_r,
          routeBuilder: emptyShellRouteBuilder,
          routes: [
            StateRoute(
              state_r_1,
              routeBuilder: emptyRouteBuilder,
            ),
            StateRoute.shell(
              state_r_2,
              routeBuilder: emptyShellRouteBuilder,
              routes: [
                StateRoute(
                  state_r_2_1,
                  routeBuilder: emptyRouteBuilder,
                ),
                StateRoute(
                  state_r_2_2,
                  routeBuilder: emptyRouteBuilder,
                ),
              ],
            )
          ],
        );
        var rootConfig = rootRoute.createConfig(null);

        var allConfigs = rootConfig.selfAndDescendants().toList();
        expect(allConfigs.length, 5);
        expectConfig(allConfigs, state_r, null, const [state_r_1, state_r_2]);
        expectConfig(allConfigs, state_r_1, state_r, const []);
        expectConfig(
            allConfigs, state_r_2, state_r, const [state_r_2_1, state_r_2_2]);
        expectConfig(allConfigs, state_r_2_1, state_r_2, const []);
        expectConfig(allConfigs, state_r_2_2, state_r_2, const []);
      });
    });
  });
}

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
