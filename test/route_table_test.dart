import 'package:flutter/material.dart';
import 'package:test/test.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/route_table.dart';
import 'fixture.dart';

void main() {
  group('RouteTable', () {
    group('with simple routes', () {
      var stateMachine = TreeStateMachine(dataStateTree());
      var routeTree = dataRouter(stateMachine);

      group('parseRouteInformation', () {
        var expected = [
          ('/r/r', false),
          ('/r/2', true),
          ('/r/2/1', false),
          ('/r/2/2', true),
          ('/r/3', false),
        ];

        for (var (uri, parsable) in expected) {
          var routeInformation = RouteInformation(uri: Uri(path: uri));
          test('should parse linkable URI $uri', () {
            var routeTable = RouteTable(stateMachine, routeTree.routes);
            var routePath = routeTable.parseRouteInformation(
              routeInformation,
              linkableRoutes: true,
            );
            expect(routePath, parsable ? isNotNull : isNull);
          });
        }
      });

      group('toRouteInformation', () {
        var expected = [
          (DataStates.state_r, '/r'),
          (DataStates.state_r_2, '/r/2'),
          (DataStates.state_r_2_1, '/r/2/1'),
          (DataStates.state_r_2_2, '/r/2/2'),
        ];
        for (var (state, uri) in expected) {
          test('should generate route information for $state', () {
            var routeTable = RouteTable(stateMachine, routeTree.routes);
            var routePath = toRoutePath(routeTree.routeMap[state]!);
            var routeInfo = routeTable.toRouteInformation(routePath);
            expect(routeInfo, isNotNull);
            expect(routeInfo!.uri.path, uri);
          });
        }
      });
    });

    group('with parameterized routes', () {
      group('parseRouteInformation', () {
        var expected = [
          ('/r/r', DataStates.state_r, false),
          ('/r/r/2/r_2', DataStates.state_r_2, true),
          ('/r/r/2/r_2/1/r_2_1', DataStates.state_r_2_1, false),
          ('/r/r/2/r_2/2/r_2_2', DataStates.state_r_2_2, true),
          ('/r/3', DataStates.state_r_2_2, false),
        ];

        for (var (uri, state, parsable) in expected) {
          var routeInformation = RouteInformation(uri: Uri(path: uri));
          test('should parse linkable URI $uri', () async {
            var stateMachine = TreeStateMachine(dataStateTree());
            await stateMachine.start(at: state);
            var routeTree = dataRouter(stateMachine, parameterize: true);
            var routeTable = RouteTable(stateMachine, routeTree.routes);
            var routePath = routeTable.parseRouteInformation(
              routeInformation,
              linkableRoutes: true,
            );
            expect(routePath, parsable ? isNotNull : isNull);
          });
        }
      });

      group('toRouteInformation', () {
        var expected = [
          (DataStates.state_r, '/r/r'),
          (DataStates.state_r_2, '/r/r/2/r_2'),
          (DataStates.state_r_2_1, '/r/r/2/r_2/1/r_2_1'),
          (DataStates.state_r_2_2, '/r/r/2/r_2/2/r_2_2'),
        ];
        for (var (state, uri) in expected) {
          test('should generate route information for $state', () async {
            var stateMachine = TreeStateMachine(dataStateTree());
            var routeTree = dataRouter(stateMachine, parameterize: true);
            await stateMachine.start(at: state);
            var routeTable = RouteTable(stateMachine, routeTree.routes);
            var routePath = toRoutePath(routeTree.routeMap[state]!);
            var routeInfo = routeTable.toRouteInformation(routePath);
            expect(routeInfo, isNotNull);
            expect(routeInfo!.uri.path, uri);
          });
        }
      });
    });
  });
}
