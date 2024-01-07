import 'package:tree_state_router/tree_state_router.dart';

extension StateRouteConfigExtensions on StateRouteConfig {
  Iterable<StateRouteConfig> selfAndDescendants() sync* {
    Iterable<StateRouteConfig> selfAndDescendants_(
      StateRouteConfig route,
    ) sync* {
      yield route;
      for (var child in route.childRoutes) {
        yield* selfAndDescendants_(child);
      }
    }

    yield* selfAndDescendants_(this);
  }
}
