import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'builder.dart';

/// TBD: This will contain routing information parsed from the current URI.
class TreeStateRoutingState {}

/// {@template ShellTreeStateRouteBuilder}
/// A function that can build a widget providing a visualization of an active parent state in a
/// state tree, wrapping a nested router that displays active descendant states. This enables shell
/// or layout pages associated with a parent state to provide a common framing around the visuals
/// for descendant states.
///
/// The function is provided a build [context], a [stateContext] that describes the parent state to be
/// visualized, and a [nestedRouter] representing the visuals for the active states. The widget
/// produced by the function should incorporate [nestedRouter] somewhere in its widget tree.
/// {@endtemplate}
typedef ShellStateRouteBuilder = Widget Function(
  BuildContext context,
  StateRoutingContext stateContext,
  Widget nestedRouter,
);

/// {@template ShellTreeStateRoutePageBuilder}
/// {@endtemplate}
typedef ShellStateRoutePageBuilder = Page<dynamic> Function(
  BuildContext context,
  StateRoutingContext stateContext,
  Widget childRouter,
);

/// A route that creates visuals for a state in a state tree.
///
/// {@template TreeStateRoute.propSummary}
/// The route is provided with a [stateKey] identifying the tree state to be displayed. When a
/// [TreeStateRouter] detects that the state is an active state in the routers state machine, it
/// will place a page in the routers [Navigator] that displays the visuals created by this route.
///
/// The visuals that are created are specified by providing either a [routeBuilder] or a
/// [routePageBuilder]. In most cases, [routeBuilder] will be used, and the [TreeStateRouter] will
/// wrap these visuals in a routing [Page] that is appropriate for the application (Material or
/// Cupertino). If precise control of the [Page] type is needed, for example to control the specific
/// navigation transition animations, [routePageBuilder] can be provided.
/// instead.
/// {@endtemplate}
///
/// ```dart
/// var routerConfig = TreeStateRouter(
///   routes: [
///     TreeStateRoute(
///       States.state1,
///       routeBuilder: (BuildContext ctx, TreeStateRoutingContext stateCtx) {
///         return Center(
///           child: Column(
///             mainAxisAlignment: MainAxisAlignment.center,
///             children: [
///               const Text('This is state 1'),
///               ElevatedButton(
///                 onPressed: () => stateCtx.currentState.post(AMessage()),
///                 child: const Text('Send a message'),
///               )],
///           ));
///       }),
///   ]);
/// ```
class StateRoute implements StateRouteConfigProvider {
  StateRoute._(
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

  /// Constructs a [StateRoute].
  factory StateRoute(
    StateKey stateKey, {
    StateRoutePageBuilder? routePageBuilder,
    StateRouteBuilder? routeBuilder,
  }) =>
      StateRoute._(
        stateKey,
        routeBuilder: routeBuilder,
        routePageBuilder: routePageBuilder,
        isPopup: false,
      );

  /// Constructs a [StateRoute] that displays its visuals in a [PopupRoute].
  factory StateRoute.popup(
    StateKey stateKey, {
    StateRouteBuilder? routeBuilder,
  }) =>
      StateRoute._(
        stateKey,
        routeBuilder: routeBuilder,
        routePageBuilder: null,
        isPopup: true,
      );

  /// Constructs a [StateRoute] for a parent state that provides common layout (i.e. a 'shell')
  /// wrapping a nested router that displays visuals for active descendant states.
  ///
  /// A list of [routes] must be provided that determine the routing for descendant states of the
  /// parent state identfied by [stateKey].
  factory StateRoute.shell(
    StateKey stateKey, {
    required List<StateRouteConfigProvider> routes,
    ShellStateRoutePageBuilder? routePageBuilder,
    ShellStateRouteBuilder? routeBuilder,
    bool enableTransitions = false,
  }) {
    var nestedRouter = NestedTreeStateRouter(
      key: ValueKey(stateKey),
      parentStateKey: stateKey,
      routes: routes,
      enableTransitions: enableTransitions,
    );
    return StateRoute._(
      stateKey,
      routeBuilder: routeBuilder != null
          ? (ctx, stateCtx) => routeBuilder(ctx, stateCtx, nestedRouter)
          : null,
      routePageBuilder: routePageBuilder != null
          ? (ctx, stateCtx) => routePageBuilder(ctx, stateCtx, nestedRouter)
          : null,
      isPopup: false,
    );
  }

  /// Identifies the tree state associated with this route.
  final StateKey stateKey;

  /// {@template StateRoute.routeBuilder}
  /// The builder function providing the visuals for this route.
  ///
  /// May be `null` if [routePageBuilder] is provided instead.
  /// {@endtemplate}
  final StateRouteBuilder? routeBuilder;

  /// {@template StateRoute.routePageBuilder}
  /// The builder function that constructs the routing [Page] for this route.
  ///
  /// If `null`, the [TreeStateRouter] will choose an appropriate [Page] type based on the application
  /// typoe (Material, Cupertino, etc.).
  /// {@endtemplate}
  final StateRoutePageBuilder? routePageBuilder;

  /// {@template StateRoute.isPopup}
  /// Indicates if this route will display its visuals in a [PopupRoute].
  /// {@endtemplate}
  final bool isPopup;

  @override
  late final StateRouteConfig config = StateRouteConfig(
    stateKey,
    routeBuilder: routeBuilder,
    routePageBuilder: routePageBuilder,
    isPopup: isPopup,
  );
}

typedef TreeStateRouteBuilder1<DAnc> = Widget Function(
  BuildContext context,
  StateRoutingContext stateContext,
  DAnc data,
);

typedef TreeStateRoutePageBuilder1<DAnc> = Page<void> Function(
  BuildContext context,
  Widget Function(TreeStateRouteBuilder1<DAnc> buildPageContent)
      wrapPageContent,
);

class TreeStateRoute1<DAnc> implements StateRouteConfigProvider {
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
    required DataStateRouteBuilder<DAnc> routeBuilder,
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
  late final List<StateDataResolver> _resolvers = [
    StateDataResolver<DAnc>(ancestorStateKey)
  ];

  @override
  late final config = StateRouteConfig(stateKey,
      routeBuilder: routeBuilder != null
          ? (context, stateContext) =>
              _createDataTreeStateBuilder(stateContext, routeBuilder!)
          : null,
      routePageBuilder: routePageBuilder != null
          ? (context, stateContext) => routePageBuilder!.call(
                context,
                (buildPageContent) => _createDataTreeStateBuilder(
                  stateContext,
                  buildPageContent,
                ),
              )
          : null,
      isPopup: isPopup,
      dependencies: _resolvers.map((e) => e.stateKey!).toList());

  DataStateBuilder _createDataTreeStateBuilder(
    StateRoutingContext stateContext,
    DataStateRouteBuilder<DAnc> buildPageContent,
  ) {
    return DataStateBuilder(
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
  StateRoutingContext stateContext,
  DAnc1 ancestor1Data,
  DAnc2 ancestor2Data,
);

typedef TreeStateRoutePageBuilder2<DAnc1, DAnc2> = Page<void> Function(
  BuildContext context,
  Widget Function(TreeStateRouteBuilder2<DAnc1, DAnc2> buildPageContent)
      wrapPageContent,
);

class TreeStateRoute2<DAnc1, DAnc2> implements StateRouteConfigProvider {
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
    required DataStateRouteBuilder2<DAnc1, DAnc2> routeBuilder,
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
  late final config = StateRouteConfig(
    stateKey,
    routeBuilder: routeBuilder != null
        ? (context, stateContext) => _createDataTreeStateBuilder(
              stateContext,
              routeBuilder!,
            )
        : null,
    routePageBuilder: routePageBuilder != null
        ? (context, stateContext) => routePageBuilder!.call(
              context,
              (buildPageContent) => _createDataTreeStateBuilder(
                stateContext,
                buildPageContent,
              ),
            )
        : null,
    isPopup: isPopup,
    dependencies: _resolvers.map((e) => e.stateKey!).toList(),
  );

  DataStateBuilder _createDataTreeStateBuilder(
    StateRoutingContext stateContext,
    DataStateRouteBuilder2<DAnc1, DAnc2> buildPageContent,
  ) {
    return DataStateBuilder(
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
  StateRoutingContext stateContext,
  DAnc1 ancestor1Data,
  DAnc2 ancestor2Data,
  DAnc3 ancestor3Data,
);

typedef TreeStateRoutePageBuilder3<DAnc1, DAnc2, DAnc3> = Page<void> Function(
  BuildContext context,
  Widget Function(TreeStateRouteBuilder3<DAnc1, DAnc2, DAnc3> buildPageContent)
      wrapPageContent,
);

class TreeStateRoute3<DAnc1, DAnc2, DAnc3> implements StateRouteConfigProvider {
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
  late final config = StateRouteConfig(stateKey,
      routeBuilder: routeBuilder != null
          ? (context, stateContext) => _createDataTreeStateBuilder(
                stateContext,
                routeBuilder!,
              )
          : null,
      routePageBuilder: routePageBuilder != null
          ? (context, stateContext) => routePageBuilder!.call(
                context,
                (buildPageContent) => _createDataTreeStateBuilder(
                  stateContext,
                  buildPageContent,
                ),
              )
          : null,
      isPopup: isPopup,
      dependencies: _resolvers.map((e) => e.stateKey!).toList());

  DataStateBuilder _createDataTreeStateBuilder(
    StateRoutingContext stateContext,
    DataTreeStateRouteBuilder3<DAnc1, DAnc2, DAnc3> buildPageContent,
  ) {
    return DataStateBuilder(
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
