import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/widgets/nested_machine_router.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'builder.dart';

typedef CreateRouteConfig = StateRouteConfig Function(StateRouteConfig? parent);

/// A route that provides visuals for a state in a state tree.
///
/// {@template TreeStateRoute.propSummary}
/// The route is provided with a [StateKey] identifying the tree state to be
/// displayed. When a [TreeStateRouter] detects that the state is an active
/// state in the routers state machine, it will place a page in the routers
/// [Navigator] that displays the visuals created by this route.
///
/// The visuals that are created are specified by providing either a
/// [StateRouteBuilder] or a [StateRoutePageBuilder]. In most cases, a
/// [StateRouteBuilder] will be used, and the [TreeStateRouter] will wrap these
/// visuals in a routing [Page] that is appropriate for the application
/// (Material or Cupertino). If precise control of the [Page] type is needed,
/// for example to control the specific navigation transition animations,
/// a [StateRoutePageBuilder] can be provided instead.
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
  StateRoute._(this._createRouteConfig);

  /// Constructs a [StateRoute] that provides visuals for a state in a state
  /// tree.
  ///
  /// {@template StateRoute.stateKey}
  /// A [stateKey] must be provided that identifies the tree state for which
  /// visuals will be provided.
  /// {@endtemplate}
  ///
  /// {@template StateRoute.buildersSummary}
  /// A [routeBuilder] or [routePageBuilder] function must be provided that
  /// will create the visuals. In most cases, [routeBuilder] will likely be
  /// used, and the [TreeStateRouter] will wrap these visuals in a routing
  /// [Page] that is appropriate for the application (Material or Cupertino). If
  /// precise control of the [Page] type is needed, for example to control the
  /// specific navigation transition animations, [routePageBuilder] can be
  /// provided instead.
  /// {@endtemplate}
  ///
  /// {@template StateRoute.path}
  /// A [path] can optionally be provided that provides additional path
  /// information when the route integrates with platform routing (in
  /// conjunction with [TreeStateRouter.platformRouting]).
  /// {@endtemplate}
  factory StateRoute(
    StateKey stateKey, {
    StateRouteBuilder? routeBuilder,
    StateRoutePageBuilder? routePageBuilder,
    RoutePathConfig? path,
  }) =>
      StateRoute._(
        (parentRoute) => StateRouteConfig(
          stateKey,
          routeBuilder: routeBuilder,
          routePageBuilder: routePageBuilder,
          isPopup: false,
          path: path,
          childRoutes: const [],
          parentRoute: parentRoute,
        ),
      );

  /// Constructs a [StateRoute] that displays its visuals in a [PopupRoute].
  factory StateRoute.popup(
    StateKey stateKey, {
    StateRouteBuilder? routeBuilder,
    RoutePathConfig? path,
  }) =>
      StateRoute._(
        (parentRoute) => StateRouteConfig(
          stateKey,
          routeBuilder: routeBuilder,
          routePageBuilder: null,
          isPopup: true,
          path: path,
          childRoutes: const [],
          parentRoute: parentRoute,
        ),
      );

  /// Constructs a [StateRoute] for a parent state that provides common layout
  /// (i.e. a 'shell') wrapping a nested router that displays visuals for active
  /// descendant states.
  ///
  /// {@macro StateRoute.stateKey}
  ///
  /// A list of [routes] must be provided that determine the routing for
  /// descendant states of the parent state identfied by [stateKey].
  ///
  /// {@macro StateRoute.buildersSummary}
  ///
  /// When the [routeBuilder] and [routePageBuilder] functions are called, they
  /// are provided a `nestedRouter` widget that displays the visuals for the
  /// active descendant states. The builder functions can place this widget as
  /// desired in their layout.
  ///
  /// {@macro StateRoute.path}
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
    DefaultScaffoldingBuilder? defaultScaffolding,
    RoutePathConfig? path,
  }) =>
      StateRoute._(
        (parentRoute) {
          var childRoutes = <StateRouteConfig>[];
          var nestedRouter = DescendantStatesRouter(
            key: ValueKey(stateKey),
            anchorKey: stateKey,
            routes: childRoutes,
            defaultScaffolding: defaultScaffolding,
            enableTransitions: enableTransitions,
          );

          var config = StateRouteConfig(
            stateKey,
            routeBuilder: routeBuilder != null
                ? (ctx, stateCtx) => routeBuilder(ctx, stateCtx, nestedRouter)
                : null,
            routePageBuilder: routePageBuilder != null
                ? (buildContext, wrapPageContent) => routePageBuilder(
                    buildContext,
                    (buildPageContent) => wrapPageContent(
                        (context, stateContext) => buildPageContent(
                              context,
                              stateContext,
                              nestedRouter,
                            )))
                : null,
            isPopup: false,
            path: path,
            childRoutes: childRoutes,
            parentRoute: parentRoute,
          );

          childRoutes.addAll(routes.map((e) => e.createConfig(config)));

          return config;
        },
      );

  /// Constructs a [StateRoute] for a machine state that serves as a host for a
  /// state machine nested within a parent state machine.
  ///
  /// {@macro StateRoute.stateKey}
  ///
  /// A list of [routes] must be provided that determine the routing for states
  /// within the nested state machine, *not* the outer state machine.
  ///
  /// {@macro StateRoute.buildersSummary}
  ///
  /// In a similar manner to [StateRoute.shell], when the [routeBuilder] and
  /// [routePageBuilder] functions are called, they are provided a
  /// `nestedRouter` widget that displays the visuals for the active state(s).
  ///  The builder functions can place this widget as desired in their layout.
  ///
  /// [enableTransitions] and [defaultScaffolding] work in the same manner as
  /// [TreeStateRouter.enableTransitions] and
  /// [TreeStateRouter.defaultScaffolding], respectively.
  ///
  /// {@macro StateRoute.path}
  factory StateRoute.machine(
    DataStateKey<MachineTreeStateData> stateKey, {
    required List<StateRouteConfigProvider> routes,
    ShellStateRouteBuilder? routeBuilder,
    ShellStateRoutePageBuilder? routePageBuilder,
    bool enableTransitions = false,
    DefaultScaffoldingBuilder? defaultScaffolding,
    RoutePathConfig? path,
  }) =>
      StateRoute._((parent) {
        var childRouteConfigs = <StateRouteConfig>[];
        NestedStateMachineRouter nestedRouter() => NestedStateMachineRouter(
              key: ValueKey(stateKey),
              machineStateKey: stateKey,
              routes: childRouteConfigs,
              defaultScaffolding: defaultScaffolding,
              enableTransitions: enableTransitions,
            );

        var config = StateRouteConfig(
          stateKey,
          routeBuilder: routeBuilder != null
              ? (ctx, stateCtx) => routeBuilder(ctx, stateCtx, nestedRouter())
              : null,
          routePageBuilder: routePageBuilder != null
              ? (buildContext, wrapPageContent) => routePageBuilder(
                  buildContext,
                  (buildPageContent) => wrapPageContent(
                      (context, stateContext) => buildPageContent(
                            context,
                            stateContext,
                            nestedRouter(),
                          )))
              : null,
          isPopup: false,
          path: path,
          childRoutes: childRouteConfigs,
          parentRoute: parent,
        );

        childRouteConfigs.addAll(routes.map((e) => e.createConfig(config)));

        return config;
      });

  final CreateRouteConfig _createRouteConfig;

  @override
  StateRouteConfig createConfig(StateRouteConfig? parent) =>
      _createRouteConfig(parent);
}

/// {@template ShellTreeStateRouteBuilder}
/// A function that can build a widget providing a visualization of an active
/// parent state in a state tree, wrapping a nested router that displays active
/// descendant states. This enables shell or layout pages associated with a
/// parent state to provide a common framing around the visual for descendant
/// states.
///
/// The function is provided a build [context], a [stateContext] that describes
/// the parent state to be visualized, and a [nestedRouter] representing the
/// visuals for the active states. The widget produced by the function should
/// incorporate [nestedRouter] somewhere in its widget tree.
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

/// A route that creates visuals for a state in a state tree, using state data
/// of type [DAnc] obtained from an ancestor data state.
///
/// This route is used in a very similar manner as [StateRoute], with the
/// addition of providing the [DataStateKey] of the ancestor state whose data
/// should be obtained. The data value is yen made available to the builder
/// functions.
class StateRoute1<DAnc> implements StateRouteConfigProvider {
  StateRoute1._(this._createRouteConfig);

  /// Constructs a [StateRoute1].
  ///
  /// A [stateKey] must be provided that identifies the tree state for which
  /// visuals will be provided, as well as an [ancestorStateKey] that identifies
  /// the ancestor data state will provide its state data to the builder
  /// functions.
  ///
  /// {@macro StateRoute.buildersSummary}
  ///
  /// When the [routeBuilder] and [routePageBuilder] functions are called, they
  /// are provided a `data` argument containing the state data obtained from
  /// [ancestorStateKey].
  ///
  /// {@macro StateRoute.path}
  factory StateRoute1(
    StateKey stateKey, {
    required DataStateKey<DAnc> ancestorStateKey,
    DataStateRouteBuilder<DAnc>? routeBuilder,
    DataStateRoutePageBuilder<DAnc>? routePageBuilder,
    RoutePathConfig? path,
  }) =>
      StateRoute1._((parent) {
        return createDataStateRouteConfig1<DAnc>(
          parent,
          stateKey,
          routeBuilder,
          routePageBuilder,
          [StateDataResolver<DAnc>(ancestorStateKey)],
          false,
          path,
          const [],
        );
      });

  /// Constructs a [StateRoute1] that displays its visuals in a [PopupRoute].
  factory StateRoute1.popup(
    StateKey stateKey, {
    required DataStateKey<DAnc> ancestorStateKey,
    required DataStateRouteBuilder<DAnc> routeBuilder,
  }) =>
      StateRoute1._((parent) {
        return createDataStateRouteConfig1<DAnc>(
          parent,
          stateKey,
          routeBuilder,
          null,
          [StateDataResolver<DAnc>(ancestorStateKey)],
          true,
          null,
          const [],
        );
      });

  final CreateRouteConfig _createRouteConfig;

  @override
  StateRouteConfig createConfig(StateRouteConfig? parent) =>
      _createRouteConfig(parent);
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
  StateRoute2._(this._createRouteConfig);

  /// Constructs a [StateRoute1].
  factory StateRoute2(
    StateKey stateKey, {
    required DataStateKey<DAnc1> ancestor1StateKey,
    required DataStateKey<DAnc2> ancestor2StateKey,
    DataStateRouteBuilder2<DAnc1, DAnc2>? routeBuilder,
    DataStateRoutePageBuilder2<DAnc1, DAnc2>? routePageBuilder,
    RoutePathConfig? path,
  }) =>
      StateRoute2._((parent) {
        return createDataStateRouteConfig2(
          parent,
          stateKey,
          routeBuilder,
          routePageBuilder,
          [
            StateDataResolver<DAnc1>(ancestor1StateKey),
            StateDataResolver<DAnc2>(ancestor2StateKey),
          ],
          false,
          path,
          const [],
        );
      });

  /// Constructs a [StateRoute1] that displays its visuals in a [PopupRoute].
  factory StateRoute2.popup(
    StateKey stateKey, {
    required DataStateKey<DAnc1> ancestor1StateKey,
    required DataStateKey<DAnc2> ancestor2StateKey,
    required DataStateRouteBuilder2<DAnc1, DAnc2>? routeBuilder,
  }) =>
      StateRoute2._((parent) {
        return createDataStateRouteConfig2(
          parent,
          stateKey,
          routeBuilder,
          null,
          [
            StateDataResolver<DAnc1>(ancestor1StateKey),
            StateDataResolver<DAnc2>(ancestor2StateKey),
          ],
          true,
          null,
          const [],
        );
      });

  final CreateRouteConfig _createRouteConfig;

  @override
  StateRouteConfig createConfig(StateRouteConfig? parent) =>
      _createRouteConfig(parent);
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
  StateRoute3._(this._createRouteConfig);

  /// Constructs a [StateRoute3].
  factory StateRoute3(
    StateKey stateKey, {
    required DataStateKey<DAnc1> ancestor1StateKey,
    required DataStateKey<DAnc2> ancestor2StateKey,
    required DataStateKey<DAnc3> ancestor3StateKey,
    DataStateRouteBuilder3<DAnc1, DAnc2, DAnc3>? routeBuilder,
    DataStateRoutePageBuilder3<DAnc1, DAnc2, DAnc3>? routePageBuilder,
    RoutePathConfig? path,
  }) =>
      StateRoute3._((parent) {
        return createDataStateRouteConfig3(
          parent,
          stateKey,
          routeBuilder,
          routePageBuilder,
          [
            StateDataResolver<DAnc1>(ancestor1StateKey),
            StateDataResolver<DAnc2>(ancestor2StateKey),
            StateDataResolver<DAnc2>(ancestor2StateKey),
          ],
          false,
          path,
          const [],
        );
      });

  factory StateRoute3.popup(
    StateKey stateKey, {
    required DataStateKey<DAnc1> ancestor1StateKey,
    required DataStateKey<DAnc2> ancestor2StateKey,
    required DataStateKey<DAnc3> ancestor3StateKey,
    required DataStateRouteBuilder3<DAnc1, DAnc2, DAnc3> routeBuilder,
  }) =>
      StateRoute3._((parent) {
        return createDataStateRouteConfig3(
          parent,
          stateKey,
          routeBuilder,
          null,
          [
            StateDataResolver<DAnc1>(ancestor1StateKey),
            StateDataResolver<DAnc2>(ancestor2StateKey),
            StateDataResolver<DAnc2>(ancestor2StateKey),
          ],
          true,
          null,
          const [],
        );
      });

  final CreateRouteConfig _createRouteConfig;

  @override
  StateRouteConfig createConfig(StateRouteConfig? parent) =>
      _createRouteConfig(parent);
}
