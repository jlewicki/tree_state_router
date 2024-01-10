import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tree_state_router/tree_state_router.dart';

void main() {
  group('RoutePath', () {
    group('RoutePath.new', () {
      test('shoud assert not empty', () {
        expect(() => RoutePath(''), throwsA(isA<AssertionError>()));
      });

      var invalidTemplates = ['/foo', '\\foo', 'foo/', 'foo\\', 'user/:userId'];
      for (var template in invalidTemplates) {
        test('should assert for path template $template', () {
          expect(() => RoutePath(template), throwsA(isA<AssertionError>()));
        });
      }
    });

    group('generatePath', () {
      var templates = ['foo', 'foo/bar'];
      for (var template in templates) {
        test('should generate path for $template', () {
          var routePath = RoutePath(template);
          var path = routePath.generateUriPath(null);
          expect(path, template);
        });
      }

      test('should ignore data arg', () {
        var template = 'foo';
        var routePath = RoutePath(template);
        var path = routePath.generateUriPath(Object());
        expect(path, template);
      });
    });

    group('parameters', () {
      test('should list path parameters', () {
        var routePath = DataRoutePath<SomeData>('foo/bar');
        expect(routePath.parameters.isEmpty, isTrue);
      });
    });
  });

  group('DataRoutePath', () {
    group('DataRoutePath()', () {
      var invalidTemplates = ['/foo', '\\foo', 'foo/', 'foo\\', 'user/:userId'];
      for (var template in invalidTemplates) {
        test('should assert for path template $template', () {
          expect(() => DataRoutePath<SomeData>(template),
              throwsA(isA<AssertionError>()));
        });
      }

      group('generatePath', () {
        var templates = ['foo', 'foo/bar'];
        for (var template in templates) {
          test('should generate path for $template', () {
            var routePath = DataRoutePath<SomeData>(template);
            var path = routePath.generateUriPath(null);
            expect(path, template);
          });
        }
      });

      group('matchPath', () {
        var templates = ['foo', 'foo/bar'];
        for (var template in templates) {
          test('should match path for $template', () {
            var routePath = DataRoutePath<SomeData>(template);
            var match = routePath.matchUriPath('/$template');
            expect(match, isNotNull);
            expect(match!.pathMatch, '/$template');
          });
        }
      });

      group('parameters', () {
        test('should list path parameters', () {
          var routePath = DataRoutePath<SomeData>('foo/bar');
          expect(routePath.parameters.isEmpty, isTrue);
        });
      });
    });

    group('DataRoutePath.withParams()', () {
      var template = 'user/:userId/address/:addressId';
      var routePath = DataRoutePath<SomeData>.parameterized(
        template,
        pathArgs: (data) => {
          'userId': data.userId.toString(),
          'addressId': 'address-${data.addressId.toString()}',
        },
        initialData: (pathArgs) => SomeData(
          int.parse(pathArgs['userId']!),
          int.parse(pathArgs['addressId']!.substring('address-'.length)),
        ),
      );

      group('generatePath', () {
        test('should generate path with path args', () {
          var path = routePath.generateUriPath(SomeData(1, 2));
          expect(path, 'user/1/address/address-2');
        });

        test('should throw if arguments are missing', () {
          var template = 'user/:userId/address/:addressId';
          var routePath = DataRoutePath<SomeData>.parameterized(
            template,
            pathArgs: (data) => {
              'userId': data.userId.toString(),
            },
          );
          expect(
            () => routePath.generateUriPath(SomeData(1, 2)),
            throwsA(isA<RoutePathError>()),
          );
        });
      });

      group('matchPath', () {
        test('should match path ', () {
          var match = routePath.matchUriPath('/user/2/address/address-1/abc');
          expect(match, isNotNull);
          expect(match!.pathMatch, '/user/2/address/address-1');
          expect(match.initialData, isA<SomeData>());
          var data = match.initialData as SomeData;
          expect(data.userId, 2);
          expect(data.addressId, 1);
        });
      });

      group('parameters', () {
        test('should list path parameters', () {
          expect(
              const ListEquality<String>()
                  .equals(routePath.parameters, ['userId', 'addressId']),
              isTrue);
        });
      });
    });
  });
}

class SomeData {
  SomeData(this.userId, this.addressId);
  int userId = 0;
  int addressId = 0;
}
