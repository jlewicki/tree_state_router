import 'package:tree_state_router/tree_state_router.dart';

extension StateRouteConfigExtensions on StateRouteConfig {
  Iterable<StateRouteConfig> descendants() sync* {
    for (var child in childRoutes) {
      yield child;
      yield* child.descendants();
    }
  }

  Iterable<StateRouteConfig> selfAndDescendants() sync* {
    yield this;
    yield* descendants();
  }

  Iterable<StateRouteConfig> ancestors() sync* {
    var ancestor = parentRoute;
    while (ancestor != null) {
      yield ancestor;
      ancestor = ancestor.parentRoute;
    }
  }

  Iterable<StateRouteConfig> selfAndAncestors() sync* {
    yield this;
    yield* ancestors();
  }

  Iterable<StateRouteConfig> leaves() {
    return selfAndDescendants().where((r) => r.childRoutes.isEmpty);
  }
}
