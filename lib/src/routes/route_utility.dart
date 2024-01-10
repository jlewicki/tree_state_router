import 'package:tree_state_router/tree_state_router.dart';

extension StateRouteConfigExtensions on StateRouteInfo {
  Iterable<StateRouteInfo> descendants() sync* {
    for (var child in childRoutes) {
      yield child;
      yield* child.descendants();
    }
  }

  Iterable<StateRouteInfo> selfAndDescendants() sync* {
    yield this;
    yield* descendants();
  }

  Iterable<StateRouteInfo> ancestors() sync* {
    var ancestor = parentRoute;
    while (ancestor != null) {
      yield ancestor;
      ancestor = ancestor.parentRoute;
    }
  }

  Iterable<StateRouteInfo> selfAndAncestors() sync* {
    yield this;
    yield* ancestors();
  }

  Iterable<StateRouteInfo> leaves() {
    return selfAndDescendants().where((r) => r.childRoutes.isEmpty);
  }
}
