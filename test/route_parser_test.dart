import 'package:flutter/widgets.dart';
import 'package:test/test.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/route_parser.dart';
import 'package:tree_state_router/src/routes/route_utility.dart';
import 'package:tree_state_router/tree_state_router.dart';

import 'fixture.dart';

void main() {
  group('TreeStateRouteInformationParser', () {
    StateRouteInfo? currentRoute;

    Future<TreeStateRouteInformationParser> setUpSubject(
        {StateKey? initialState}) async {
      var routerConfig = platformDataRouter();
      var stateMachine = routerConfig.stateMachine;
      var currentState = await stateMachine.start(at: initialState);
      currentRoute = routerConfig.routeMap[currentState.key]!;
      return routerConfig.routeInformationParser
          as TreeStateRouteInformationParser;
    }

    group('restoreRouteInformation', () {
      test('should return RouteInformation', () async {
        var parser = await setUpSubject();
        var routePath = TreeStateRoutePath(
            currentRoute!.selfAndAncestors().toList().reversed.toList());

        var routeInfo = parser.restoreRouteInformation(routePath);
        expect(routeInfo, isNotNull);
        expect(routeInfo!.uri.path, '/r/2/1');
      });

      test('should return nuil RouteInformation for push path', () async {
        var parser = await setUpSubject();
        var routePath = TreeStateRoutePath(
                currentRoute!.selfAndAncestors().toList().reversed.toList())
            .asPush(true);

        var routeInfo = parser.restoreRouteInformation(routePath);
        expect(routeInfo, isNull);
      });
    });

    group('parseRouteInformation', () {
      test('should parse route path', () async {
        var parser = await setUpSubject(initialState: DataStates.state_r_2_2);
        var routeInfo = RouteInformation(
            uri: Uri(path: '/r/2/2', queryParameters: {'foo': 'bar'}));

        var routePath = await parser.parseRouteInformation(routeInfo);

        expect(routePath, isNotNull);
        expect(routePath.isDeepLinkable, true);
        expect(
            routePath.routes.map((e) => e.stateKey).toList(),
            containsAllInOrder([
              DataStates.state_r,
              DataStates.state_r_2,
              DataStates.state_r_2_2
            ]));
        expect(routePath.platformUri, isNotNull);
        expect(routePath.platformUri!.path, '/r/2/2');
        expect(routePath.platformUri!.query, 'foo=bar');
      });

      test('should parse default route path if route for uri is not linkable ',
          () async {
        var parser = await setUpSubject();
        var routeInfo = RouteInformation(uri: Uri(path: '/r/2/1'));

        var routePath = await parser.parseRouteInformation(routeInfo);

        expect(routePath, isNotNull);
        expect(routePath.isDeepLinkable, false);
        expect(routePath.isEmpty, true);
        expect(routePath.platformUri, isNull);
      });
    });
  });
}
