import 'package:test/test.dart';
import 'package:tree_state_router/src/routes/route_utility.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'fixture.dart';

void main() {
  group('DataStateRoute', () {
    group('createConfig', () {
      test('should create a route tree for a single route', () {
        var rootRoute = DataStateRoute(
          DataStates.state_r,
          routeBuilder: emptyDataRouteBuilder,
        );
        var rootConfig = rootRoute.createInfo(null);
        expect(rootConfig.stateKey, DataStates.state_r);
        expect(rootConfig.parentRoute, isNull);
        expect(rootConfig.childRoutes, isEmpty);
      });

      test('should create a route tree', () {
        var rootRoute = DataStateRoute.shell(
          DataStates.state_r,
          routeBuilder: emptyShellDataRouteBuilder,
          routes: [
            DataStateRoute(
              DataStates.state_r_1,
              routeBuilder: emptyDataRouteBuilder,
            ),
            DataStateRoute.shell(
              DataStates.state_r_2,
              routeBuilder: emptyShellDataRouteBuilder,
              routes: [
                DataStateRoute(
                  DataStates.state_r_2_1,
                  routeBuilder: emptyDataRouteBuilder,
                ),
                DataStateRoute(
                  DataStates.state_r_2_2,
                  routeBuilder: emptyDataRouteBuilder,
                ),
              ],
            )
          ],
        );
        var rootConfig = rootRoute.createInfo(null);

        var allConfigs = rootConfig.selfAndDescendants().toList();
        expect(allConfigs.length, 5);
        expectConfig(
          allConfigs,
          DataStates.state_r,
          null,
          const [DataStates.state_r_1, DataStates.state_r_2],
        );
        expectConfig(
          allConfigs,
          DataStates.state_r_1,
          DataStates.state_r,
          const [],
        );
        expectConfig(
          allConfigs,
          DataStates.state_r_2,
          DataStates.state_r,
          const [DataStates.state_r_2_1, DataStates.state_r_2_2],
        );
        expectConfig(
          allConfigs,
          DataStates.state_r_2_1,
          DataStates.state_r_2,
          const [],
        );
        expectConfig(
          allConfigs,
          DataStates.state_r_2_2,
          DataStates.state_r_2,
          const [],
        );
      });
    });
  });
}
