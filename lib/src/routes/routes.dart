import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';

import 'builder.dart';

// Page<void> buildAndWrap<T>(
//   BuildContext ctx,
//   Widget Function(DataTreeStateRouteBuilder<T> buildDataPageContent) wrapDataPageContent,
// ) {
//   return MaterialPage(child: wrapDataPageContent((ctx, stateCtx, data) {
//     return const Placeholder();
//   }));
// }

/// TBD: This will contain routing information parsed from the current URI.
class TreeStateRoutingState {}

class TreeStateRoutingContext {
  TreeStateRoutingContext(this.currentState);
  final CurrentState currentState;
  final TreeStateRoutingState routingState = TreeStateRoutingState();
}

abstract class TreeStateRouteConfigProvider {
  TreeStateRouteConfig get config;
}

/// {@template TreeStateRouteBuilder}
/// A function that can widget provides a visualization of an active state in a state tree.
///
/// The function is provided a build [context], and a [stateContext] that describes the state to be
/// visualized.
/// {@endtemplate}
typedef TreeStateRouteBuilder = Widget Function(
  BuildContext context,
  TreeStateRoutingContext stateContext,
);

/// {@template TreeStateRoutePageBuilder}
/// A function that can build a routing [Page] that provides a visualization of an active state in
/// a state tree.
///
/// The function is provided a build [context], and a [stateContext] that describes the state to be
/// visualized.
/// {@endtemplate}
typedef TreeStateRoutePageBuilder = Page<dynamic> Function(
  BuildContext context,
  TreeStateRoutingContext stateContext,
);

class TreeStateRouteConfig {
  TreeStateRouteConfig(
    this.stateKey, {
    this.routeBuilder,
    this.routePageBuilder,
    this.isPopup = false,
    this.dependencies = const [],
  });
  final StateKey stateKey;
  final TreeStateRouteBuilder? routeBuilder;
  final TreeStateRoutePageBuilder? routePageBuilder;
  final bool isPopup;
  final List<DataStateKey> dependencies;
}

class TreeStateRoute implements TreeStateRouteConfigProvider {
  TreeStateRoute._(
    this.stateKey, {
    required this.routePageBuilder,
    required this.routeBuilder,
    required this.isPopup,
  })  : assert(routePageBuilder != null || routeBuilder != null,
            "One of routePageBuilder or routeBuilder must be provided"),
        assert(!(routePageBuilder != null && routeBuilder != null),
            "Only one of routePageBuilder or routeBuilder can be provided"),
        assert((isPopup && routePageBuilder == null) || !isPopup,
            "routePageBuilder is not compatible with popup routes.");

  /// Constructs a [TreeStateRoute].
  factory TreeStateRoute(
    StateKey stateKey, {
    TreeStateRoutePageBuilder? routePageBuilder,
    TreeStateRouteBuilder? routeBuilder,
  }) =>
      TreeStateRoute._(
        stateKey,
        routeBuilder: routeBuilder,
        routePageBuilder: routePageBuilder,
        isPopup: false,
      );

  factory TreeStateRoute.popup(
    StateKey stateKey, {
    TreeStateRouteBuilder? routeBuilder,
  }) =>
      TreeStateRoute._(
        stateKey,
        routeBuilder: routeBuilder,
        routePageBuilder: null,
        isPopup: true,
      );

  /// The state key identifying the tree state associated with this route.
  final StateKey stateKey;

  /// {@macro TreeStateRoutePageBuilder}
  final TreeStateRoutePageBuilder? routePageBuilder;

  /// {@macro TreeStateRouteBuilder}
  ///
  /// If provided, tree state router will choose an appropriate [Page] type based on the application
  /// typoe (Material, Cupertino, etc.).
  final TreeStateRouteBuilder? routeBuilder;

  /// Indicates if this is a popup route.
  final bool isPopup;

  @override
  late final TreeStateRouteConfig config = TreeStateRouteConfig(
    stateKey,
    routeBuilder: routeBuilder,
    routePageBuilder: routePageBuilder,
    isPopup: isPopup,
  );
}

typedef TreeStateRouteBuilder1<D> = Widget Function(
  BuildContext context,
  TreeStateRoutingContext stateContext,
  D data,
);

typedef TreeStateRoutePageBuilder1<D> = Page<void> Function(
  BuildContext context,
  Widget Function(TreeStateRouteBuilder1<D> buildPageContent) wrapPageContent,
);

class TreeStateRoute1<DAnc> implements TreeStateRouteConfigProvider {
  TreeStateRoute1._(
    this.stateKey, {
    required this.ancestorStateKey,
    this.routeBuilder,
    this.routePageBuilder,
    this.isPopup = false,
  });

  TreeStateRoute1(
    this.stateKey, {
    required this.ancestorStateKey,
    this.routeBuilder,
    this.routePageBuilder,
  }) : isPopup = false;

  factory TreeStateRoute1.popup(
    StateKey stateKey, {
    required DataStateKey<DAnc> ancestorStateKey,
    required DataTreeStateRouteBuilder<DAnc> routeBuilder,
  }) =>
      TreeStateRoute1<DAnc>._(
        stateKey,
        ancestorStateKey: ancestorStateKey,
        routeBuilder: routeBuilder,
        isPopup: true,
      );

  final StateKey stateKey;
  final DataStateKey<DAnc> ancestorStateKey;
  final TreeStateRouteBuilder1<DAnc>? routeBuilder;
  final TreeStateRoutePageBuilder1<DAnc>? routePageBuilder;
  final bool isPopup;
  late final List<StateDataResolver> _resolvers = [StateDataResolver<DAnc>(ancestorStateKey)];

  @override
  late final config = TreeStateRouteConfig(stateKey,
      routeBuilder: routeBuilder != null
          ? (context, stateContext) => _createDataTreeStateBuilder(stateContext, routeBuilder!)
          : null,
      routePageBuilder: routePageBuilder != null
          ? (context, stateContext) => routePageBuilder!.call(
                context,
                (buildPageContent) => _createDataTreeStateBuilder(stateContext, buildPageContent),
              )
          : null,
      isPopup: isPopup,
      dependencies: _resolvers.map((e) => e.stateKey!).toList());

  DataTreeStateBuilder _createDataTreeStateBuilder(
    TreeStateRoutingContext stateContext,
    DataTreeStateRouteBuilder<DAnc> buildPageContent,
  ) {
    return DataTreeStateBuilder(
      ValueKey(stateKey),
      stateKey,
      _resolvers,
      (context, dataList, currentState) => buildPageContent(
        context,
        stateContext,
        dataList.getAs<DAnc>(0),
      ),
    );
  }
}

typedef TreeStateRouteBuilder2<DAnc1, DAnc2> = Widget Function(
  BuildContext context,
  TreeStateRoutingContext stateContext,
  DAnc1 ancestor1Data,
  DAnc2 ancestor2Data,
);

typedef TreeStateRoutePageBuilder2<DAnc1, DAnc2> = Page<void> Function(
  BuildContext context,
  Widget Function(TreeStateRouteBuilder2<DAnc1, DAnc2> buildPageContent) wrapPageContent,
);

class TreeStateRoute2<DAnc1, DAnc2> implements TreeStateRouteConfigProvider {
  TreeStateRoute2._(
    this.stateKey, {
    required this.ancestor1StateKey,
    required this.ancestor2StateKey,
    this.routeBuilder,
    this.routePageBuilder,
    this.isPopup = false,
  });

  TreeStateRoute2(
    this.stateKey, {
    required this.ancestor1StateKey,
    required this.ancestor2StateKey,
    this.routeBuilder,
    this.routePageBuilder,
  }) : isPopup = false;

  factory TreeStateRoute2.popup(
    StateKey stateKey, {
    required DataStateKey<DAnc1> ancestor1StateKey,
    required DataStateKey<DAnc2> ancestor2StateKey,
    required DataTreeStateRouteBuilder2<DAnc1, DAnc2> routeBuilder,
  }) =>
      TreeStateRoute2<DAnc1, DAnc2>._(
        stateKey,
        ancestor1StateKey: ancestor1StateKey,
        ancestor2StateKey: ancestor2StateKey,
        routeBuilder: routeBuilder,
        isPopup: true,
      );

  final StateKey stateKey;
  final DataStateKey<DAnc1> ancestor1StateKey;
  final DataStateKey<DAnc2> ancestor2StateKey;
  final TreeStateRouteBuilder2<DAnc1, DAnc2>? routeBuilder;
  final TreeStateRoutePageBuilder2<DAnc1, DAnc2>? routePageBuilder;
  final bool isPopup;
  late final List<StateDataResolver> _resolvers = [
    StateDataResolver<DAnc1>(ancestor1StateKey),
    StateDataResolver<DAnc2>(ancestor2StateKey)
  ];

  @override
  late final config = TreeStateRouteConfig(stateKey,
      routeBuilder: routeBuilder != null
          ? (context, stateContext) => _createDataTreeStateBuilder(stateContext, routeBuilder!)
          : null,
      routePageBuilder: routePageBuilder != null
          ? (context, stateContext) => routePageBuilder!.call(
                context,
                (buildPageContent) => _createDataTreeStateBuilder(stateContext, buildPageContent),
              )
          : null,
      isPopup: isPopup,
      dependencies: _resolvers.map((e) => e.stateKey!).toList());

  DataTreeStateBuilder _createDataTreeStateBuilder(
    TreeStateRoutingContext stateContext,
    DataTreeStateRouteBuilder2<DAnc1, DAnc2> buildPageContent,
  ) {
    return DataTreeStateBuilder(
      ValueKey(stateKey),
      stateKey,
      _resolvers,
      (context, dataList, currentState) => buildPageContent(
        context,
        stateContext,
        dataList.getAs<DAnc1>(0),
        dataList.getAs<DAnc2>(1),
      ),
    );
  }
}

typedef TreeStateRouteBuilder3<DAnc1, DAnc2, DAnc3> = Widget Function(
  BuildContext context,
  TreeStateRoutingContext stateContext,
  DAnc1 ancestor1Data,
  DAnc2 ancestor2Data,
  DAnc3 ancestor3Data,
);

typedef TreeStateRoutePageBuilder3<DAnc1, DAnc2, DAnc3> = Page<void> Function(
  BuildContext context,
  Widget Function(TreeStateRouteBuilder3<DAnc1, DAnc2, DAnc3> buildPageContent) wrapPageContent,
);

class TreeStateRoute3<DAnc1, DAnc2, DAnc3> implements TreeStateRouteConfigProvider {
  TreeStateRoute3._(
    this.stateKey, {
    required this.ancestor1StateKey,
    required this.ancestor2StateKey,
    required this.ancestor3StateKey,
    this.routeBuilder,
    this.routePageBuilder,
    this.isPopup = false,
  });

  TreeStateRoute3(
    this.stateKey, {
    required this.ancestor1StateKey,
    required this.ancestor2StateKey,
    required this.ancestor3StateKey,
    this.routeBuilder,
    this.routePageBuilder,
  }) : isPopup = false;

  factory TreeStateRoute3.popup(
    StateKey stateKey, {
    required DataStateKey<DAnc1> ancestor1StateKey,
    required DataStateKey<DAnc2> ancestor2StateKey,
    required DataStateKey<DAnc3> ancestor3StateKey,
    required DataTreeStateRouteBuilder3<DAnc1, DAnc2, DAnc3> routeBuilder,
  }) =>
      TreeStateRoute3<DAnc1, DAnc2, DAnc3>._(
        stateKey,
        ancestor1StateKey: ancestor1StateKey,
        ancestor2StateKey: ancestor2StateKey,
        ancestor3StateKey: ancestor3StateKey,
        routeBuilder: routeBuilder,
        isPopup: true,
      );

  final StateKey stateKey;
  final DataStateKey<DAnc1> ancestor1StateKey;
  final DataStateKey<DAnc2> ancestor2StateKey;
  final DataStateKey<DAnc3> ancestor3StateKey;
  final TreeStateRouteBuilder3<DAnc1, DAnc2, DAnc3>? routeBuilder;
  final TreeStateRoutePageBuilder3<DAnc1, DAnc2, DAnc3>? routePageBuilder;
  final bool isPopup;
  late final List<StateDataResolver> _resolvers = [
    StateDataResolver<DAnc1>(ancestor1StateKey),
    StateDataResolver<DAnc2>(ancestor2StateKey),
    StateDataResolver<DAnc3>(ancestor3StateKey)
  ];

  @override
  late final config = TreeStateRouteConfig(stateKey,
      routeBuilder: routeBuilder != null
          ? (context, stateContext) => _createDataTreeStateBuilder(stateContext, routeBuilder!)
          : null,
      routePageBuilder: routePageBuilder != null
          ? (context, stateContext) => routePageBuilder!.call(
                context,
                (buildPageContent) => _createDataTreeStateBuilder(stateContext, buildPageContent),
              )
          : null,
      isPopup: isPopup,
      dependencies: _resolvers.map((e) => e.stateKey!).toList());

  DataTreeStateBuilder _createDataTreeStateBuilder(
    TreeStateRoutingContext stateContext,
    DataTreeStateRouteBuilder3<DAnc1, DAnc2, DAnc3> buildPageContent,
  ) {
    return DataTreeStateBuilder(
      ValueKey(stateKey),
      stateKey,
      _resolvers,
      (context, dataList, currentState) => buildPageContent(
        context,
        stateContext,
        dataList.getAs<DAnc1>(0),
        dataList.getAs<DAnc2>(1),
        dataList.getAs<DAnc3>(3),
      ),
    );
  }
}
