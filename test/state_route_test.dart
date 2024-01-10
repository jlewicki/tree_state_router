import 'package:test/test.dart';
import 'package:tree_state_router/src/routes/route_utility.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'fixture.dart';

void main() {
  group('StateRoute', () {
    group('createConfig', () {
      test('should create a route tree for a single route', () {
        var rootRoute = StateRoute(
          States.state_r,
          routeBuilder: emptyRouteBuilder,
        );
        var rootConfig = rootRoute.createInfo(null);
        expect(rootConfig.stateKey, States.state_r);
        expect(rootConfig.parentRoute, isNull);
        expect(rootConfig.childRoutes, isEmpty);
      });

      test('should create a route tree', () {
        var rootRoute = StateRoute.shell(
          States.state_r,
          routeBuilder: emptyShellRouteBuilder,
          routes: [
            StateRoute(
              States.state_r_1,
              routeBuilder: emptyRouteBuilder,
            ),
            StateRoute.shell(
              States.state_r_2,
              routeBuilder: emptyShellRouteBuilder,
              routes: [
                StateRoute(
                  States.state_r_2_1,
                  routeBuilder: emptyRouteBuilder,
                ),
                StateRoute(
                  States.state_r_2_2,
                  routeBuilder: emptyRouteBuilder,
                ),
              ],
            )
          ],
        );
        var rootConfig = rootRoute.createInfo(null);

        var allConfigs = rootConfig.selfAndDescendants().toList();
        expect(allConfigs.length, 5);
        expectConfig(allConfigs, States.state_r, null,
            const [States.state_r_1, States.state_r_2]);
        expectConfig(allConfigs, States.state_r_1, States.state_r, const []);
        expectConfig(allConfigs, States.state_r_2, States.state_r,
            const [States.state_r_2_1, States.state_r_2_2]);
        expectConfig(
            allConfigs, States.state_r_2_1, States.state_r_2, const []);
        expectConfig(
            allConfigs, States.state_r_2_2, States.state_r_2, const []);
      });
    });
  });
}
