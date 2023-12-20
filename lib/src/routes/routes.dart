import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'builder.dart';

class RoutePath {
  RoutePath(this.path, {this.linkable = false});
  final String path;
  bool linkable;
}

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
  StateRoute._(this.stateKey,
      {required this.routePageBuilder,
      required this.routeBuilder,
      required this.isPopup,
      required this.path,
      required this.childRoutes})
      : assert(routePageBuilder != null || routeBuilder != null,
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
    String? path,
  }) =>
      StateRoute._(
        stateKey,
        routeBuilder: routeBuilder,
        routePageBuilder: routePageBuilder,
        isPopup: false,
        path: path,
        childRoutes: const [],
      );

  /// Constructs a [StateRoute] that displays its visuals in a [PopupRoute].
  factory StateRoute.popup(
    StateKey stateKey, {
    StateRouteBuilder? routeBuilder,
    String? path,
  }) =>
      StateRoute._(stateKey,
          routeBuilder: routeBuilder,
          routePageBuilder: null,
          isPopup: true,
          path: path,
          childRoutes: const []);

  /// Constructs a [StateRoute] for a parent state that provides common layout (i.e. a 'shell')
  /// wrapping a nested router that displays visuals for active descendant states.
  ///
  /// A list of [routes] must be provided that determine the routing for descendant states of the
  /// parent state identfied by [stateKey].
  ///
  /// When the [routeBuilder] and [routePageBuilder] functions are called, they are provided a
  /// `nestedRouter` widget that displays the visuals for the active descendant states. The builder
  /// functions can place this widget as desired in their layout.
  ///
  /// ```dart
  /// var routerConfig = TreeStateRouter(
  ///   routes: [
  ///     TreeStateRoute.shell(
  ///       States.parent,
  ///       routeBuilder: (_, _, Widget nestedRouter) {
  ///         return Column(
  ///           mainAxisAlignment: MainAxisAlignment.center,
  ///           children: [
  ///             const Text('This is the parent state'),
  ///             // Display the descendant states here
  ///             Expanded(child: nestedRouter),
  ///           ],
  ///         );
  ///       },
  ///       routes: [
  ///         StateRoute(States.child, routeBuilder: (_, _) =>
  ///           const Center(child: Text('This is the child state'))
  ///         )
  ///       ]),
  ///   ]);
  /// ```
  factory StateRoute.shell(
    StateKey stateKey, {
    required List<StateRouteConfigProvider> routes,
    ShellStateRouteBuilder? routeBuilder,
    ShellStateRoutePageBuilder? routePageBuilder,
    bool enableTransitions = false,
    String? path,
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
          ? (buildContext, wrapPageContent) => routePageBuilder(
              buildContext,
              (buildPageContent) =>
                  wrapPageContent((context, stateContext) => buildPageContent(
                        context,
                        stateContext,
                        nestedRouter,
                      )))
          : null,
      isPopup: false,
      path: path,
      childRoutes: routes,
    );
  }

  /// {@template StateRoute.stateKey}
  /// Identifies the tree state associated with this route.
  /// {@endtemplate}
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

  /// {@template StateRoute.path}
  /// Optional path template indicating how the route appears as part of a routing URI.
  ///
  /// If a value is provided, the route will be included when a routing URI is generated, *and*
  /// be deep-linkable when the platform sets the routing URI.
  /// {@endtemplate}
  final String? path;

  final List<StateRouteConfigProvider> childRoutes;

  @override
  late final StateRouteConfig config = StateRouteConfig(stateKey,
      routeBuilder: routeBuilder,
      routePageBuilder: routePageBuilder,
      isPopup: isPopup,
      path: path,
      childRoutes: childRoutes.map((e) => e.config).toList());
}

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

typedef ShellStateRoutePageBuilder = Page<void> Function(
  BuildContext context,
  Widget Function(ShellStateRouteBuilder buildPageContent) wrapPageContent,
);

/// A route that creates visuals for a state in a state tree, using state data of type [DAnc]
/// obtained from an ancestor data state.
///
/// This route is used in a very similar manner as [StateRoute], with the addition of providing
/// the [DataStateKey] of the ancestor state whose data should be obtained.
class StateRoute1<DAnc> implements StateRouteConfigProvider {
  StateRoute1._(
    this.stateKey, {
    required this.ancestorStateKey,
    this.routeBuilder,
    this.routePageBuilder,
    this.isPopup = false,
    this.path,
  });

  /// Constructs a [StateRoute1].
  StateRoute1(
    this.stateKey, {
    required this.ancestorStateKey,
    this.routeBuilder,
    this.routePageBuilder,
    this.path,
  }) : isPopup = false;

  /// Constructs a [StateRoute1] that displays its visuals in a [PopupRoute].
  factory StateRoute1.popup(
    StateKey stateKey, {
    required DataStateKey<DAnc> ancestorStateKey,
    required DataStateRouteBuilder<DAnc> routeBuilder,
  }) =>
      StateRoute1<DAnc>._(
        stateKey,
        ancestorStateKey: ancestorStateKey,
        routeBuilder: routeBuilder,
        isPopup: true,
      );

  /// {@macro StateRoute.stateKey}
  final StateKey stateKey;

  /// {@template StateRoute1.ancestorStateKey}
  /// Identifies the ancestor data state whose data should be obtained.
  /// {@endtemplate}
  final DataStateKey<DAnc> ancestorStateKey;

  /// {@macro StateRoute.routeBuilder}
  ///
  /// When called, this function is provided the current [DAnc] value obtained from the ancestor
  /// data state.
  final DataStateRouteBuilder<DAnc>? routeBuilder;

  /// {@macro StateRoute.routePageBuilder}
  ///
  /// When called, this function is provided the current [DAnc] value obtained from the ancestor
  /// data state.
  final DataStateRoutePageBuilder<DAnc>? routePageBuilder;

  /// {@macro StateRoute.isPopup}
  final bool isPopup;

  final String? path;

  late final List<StateDataResolver> _resolvers = [
    StateDataResolver<DAnc>(ancestorStateKey)
  ];

  @override
  late final config = createDataStateRouteConfig1(
      stateKey, routeBuilder, routePageBuilder, _resolvers, isPopup, path);
}

/// A route that creates visuals for a state in a state tree, using state data of type [DAnc1] and
/// [DAnc2 ]obtained from two ancestor data states.
///
/// This route is used in a very similar manner as [StateRoute], with the addition of providing
/// the [DataStateKey]s of the ancestor states whose data should be obtained.
///
/// Note that there is no relationship implied between the ancestor states. Either state may be an
/// ancestor of the other.
class StateRoute2<DAnc1, DAnc2> implements StateRouteConfigProvider {
  StateRoute2._(
    this.stateKey, {
    required this.ancestor1StateKey,
    required this.ancestor2StateKey,
    this.routeBuilder,
    this.routePageBuilder,
    this.isPopup = false,
  });

  /// Constructs a [StateRoute2].
  StateRoute2(
    this.stateKey, {
    required this.ancestor1StateKey,
    required this.ancestor2StateKey,
    this.routeBuilder,
    this.routePageBuilder,
  }) : isPopup = false;

  factory StateRoute2.popup(
    StateKey stateKey, {
    required DataStateKey<DAnc1> ancestor1StateKey,
    required DataStateKey<DAnc2> ancestor2StateKey,
    required DataStateRouteBuilder2<DAnc1, DAnc2> routeBuilder,
  }) =>
      StateRoute2<DAnc1, DAnc2>._(
        stateKey,
        ancestor1StateKey: ancestor1StateKey,
        ancestor2StateKey: ancestor2StateKey,
        routeBuilder: routeBuilder,
        isPopup: true,
      );

  /// {@macro StateRoute.stateKey}
  final StateKey stateKey;

  /// {@template StateRoute2.ancestor1StateKey}
  /// Identifies the first ancestor data state whose data should be obtained.
  /// {@endtemplate}
  final DataStateKey<DAnc1> ancestor1StateKey;

  /// {@template StateRoute2.ancestor2StateKey}
  /// Identifies the second ancestor data state whose data should be obtained.
  /// {@endtemplate}
  final DataStateKey<DAnc2> ancestor2StateKey;

  /// {@macro StateRoute.routeBuilder}
  ///
  /// When called, this function is provided the current [DAnc1] and [DAnc2] values obtained from
  /// the ancestor data states.
  final DataStateRouteBuilder2<DAnc1, DAnc2>? routeBuilder;

  /// {@macro StateRoute.routePageBuilder}
  ///
  /// When called, this function is provided the current [DAnc1] and [DAnc2] values obtained from
  /// the ancestor data states.
  final DataStateRoutePageBuilder2<DAnc1, DAnc2>? routePageBuilder;

  /// {@macro StateRoute.isPopup}
  final bool isPopup;

  late final List<StateDataResolver> _resolvers = [
    StateDataResolver<DAnc1>(ancestor1StateKey),
    StateDataResolver<DAnc2>(ancestor2StateKey)
  ];

  @override
  late final config = createDataStateRouteConfig2(
    stateKey,
    routeBuilder,
    routePageBuilder,
    _resolvers,
    isPopup,
  );
}

/// A route that creates visuals for a state in a state tree, using state data of type [DAnc1],
/// [DAnc2], and [DAnc3] obtained from three ancestor data states.
///
/// This route is used in a very similar manner as [StateRoute], with the addition of providing
/// the [DataStateKey]s of the ancestor states whose data should be obtained.
///
/// Note that there is no relationship implied between the ancestor states. Any state may be an
/// ancestor of the others
class StateRoute3<DAnc1, DAnc2, DAnc3> implements StateRouteConfigProvider {
  StateRoute3._(
    this.stateKey, {
    required this.ancestor1StateKey,
    required this.ancestor2StateKey,
    required this.ancestor3StateKey,
    this.routeBuilder,
    this.routePageBuilder,
    this.isPopup = false,
  });

  /// Constructs a [StateRoute3].
  StateRoute3(
    this.stateKey, {
    required this.ancestor1StateKey,
    required this.ancestor2StateKey,
    required this.ancestor3StateKey,
    this.routeBuilder,
    this.routePageBuilder,
  }) : isPopup = false;

  factory StateRoute3.popup(
    StateKey stateKey, {
    required DataStateKey<DAnc1> ancestor1StateKey,
    required DataStateKey<DAnc2> ancestor2StateKey,
    required DataStateKey<DAnc3> ancestor3StateKey,
    required DataStateRouteBuilder3<DAnc1, DAnc2, DAnc3> routeBuilder,
  }) =>
      StateRoute3<DAnc1, DAnc2, DAnc3>._(
        stateKey,
        ancestor1StateKey: ancestor1StateKey,
        ancestor2StateKey: ancestor2StateKey,
        ancestor3StateKey: ancestor3StateKey,
        routeBuilder: routeBuilder,
        isPopup: true,
      );

  /// {@macro StateRoute.stateKey}
  final StateKey stateKey;

  /// {@macro StateRoute2.ancestor1StateKey}
  final DataStateKey<DAnc1> ancestor1StateKey;

  /// {@macro StateRoute2.ancestor2StateKey}
  final DataStateKey<DAnc2> ancestor2StateKey;

  /// Identifies the third ancestor data state whose data should be obtained.
  final DataStateKey<DAnc3> ancestor3StateKey;

  /// {@macro StateRoute.routeBuilder}
  ///
  /// When called, this function is provided the current [DAnc1], [DAnc2], and [DAnc3] values
  /// obtained from the ancestor data states.
  final DataStateRouteBuilder3<DAnc1, DAnc2, DAnc3>? routeBuilder;

  /// {@macro StateRoute.routePageBuilder}
  ///
  /// When called, this function is provided the current [DAnc1], [DAnc2], and [DAnc3] values
  /// obtained from the ancestor data states.
  final DataStateRoutePageBuilder3<DAnc1, DAnc2, DAnc3>? routePageBuilder;

  /// {@macro StateRoute.isPopup}
  final bool isPopup;
  late final List<StateDataResolver> _resolvers = [
    StateDataResolver<DAnc1>(ancestor1StateKey),
    StateDataResolver<DAnc2>(ancestor2StateKey),
    StateDataResolver<DAnc3>(ancestor3StateKey)
  ];

  @override
  late final config = createDataStateRouteConfig3(
    stateKey,
    routeBuilder,
    routePageBuilder,
    _resolvers,
    isPopup,
  );
}
