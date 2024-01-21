import 'package:flutter/material.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/routes/routes.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'builder.dart';

/// {@template DataStateRouteBuilder}
/// A function that can build a widget providing a visualization of an active
/// data state in a state tree.
///
/// The function is provided a build [context], and a [stateContext] that
/// describes the state to be visualized, and the current [data] value for the
/// data state.
/// {@endtemplate}
typedef DataStateRouteBuilder<D> = Widget Function(
  BuildContext context,
  StateRoutingContext stateContext,
  D data,
);

/// {@template DataStateRoutePageBuilder}
/// A function that can build a routing [Page] that provides a visualization of
/// an active data state in a state tree.
///
/// The function is provided a build [context], and a [wrapPageContent] function
/// that must be called in order to wrap the contents of the route in a
/// specialized widget that detects statw transitions and re-renders this route
/// as necessary. The return value of the [wrapPageContent] function should be
/// used as the contents of the page.
///
/// ```dart
/// var routerConfig = TreeStateRouter(
///   routes: [
///     DataStateRoute(
///       States.dataState1,
///       pageRouteBuilder: (buildContext, wrapPageContent) {
///         return MaterialPage(child: wrapPageContent((ctx, stateCtx, data) {
///            return const Center(child: Text('State data value: $data');
///          }));
///       }),
///   ]);
/// ```
/// {@endtemplate}
typedef DataStateRoutePageBuilder<D> = Page<void> Function(
  BuildContext context,
  Widget Function(DataStateRouteBuilder<D> buildPageContent) wrapPageContent,
);

/// {@template ShellDataStateRouteBuilder}
/// {@endtemplate}
typedef ShellDataStateRouteBuilder<D> = Widget Function(
  BuildContext context,
  StateRoutingContext stateContext,
  Widget childRouter,
  D data,
);

/// {@template ShellDataStateRoutePageBuilder}
/// {@endtemplate}
typedef ShellDataStateRoutePageBuilder<D> = Page<void> Function(
  BuildContext context,
  Widget Function(ShellDataStateRouteBuilder<D> buildPageContent)
      wrapPageContent,
);

/// A route that creates visuals for a data state in a state tree.
///
/// {@macro TreeStateRoute.propSummary}
///
/// The builder functions are provided with a `data` argument that is the
/// current data value of the data state at the time the visuals are created. If
/// the state data value is updated while a message is processed by the state
/// machine, the builder function will be called again by the router with the
/// updated data value.
///
/// ```dart
/// var routerConfig = TreeStateRouter(
///   routes: [
///     DataStateRoute(
///       States.dataState1,
///       routeBuilder: (buildContext, stateContext, data) {
///            return const Center(child: Text('State data value: $data');
///        }
///     ),
///   ]);
/// ```
///
/// {@category Routes}
class DataStateRoute<D> implements StateRouteInfoBuilder {
  DataStateRoute._(this._createRouteConfig);

  /// Constructs a [DataStateRoute].
  factory DataStateRoute(
    DataStateKey<D> stateKey, {
    DataStateRouteBuilder<D>? routeBuilder,
    DataStateRoutePageBuilder<D>? routePageBuilder,
    DataRoutePath<D>? path,
  }) =>
      DataStateRoute<D>._((parent) {
        return createDataStateRouteConfig1<D>(
          parent,
          stateKey,
          routeBuilder,
          routePageBuilder,
          [StateDataResolver<D>(stateKey)],
          false,
          path,
          const [],
        );
      });

  /// Constructs a [DataStateRoute] that displays its visuals in a [PopupRoute].
  ///
  /// {@macro StateRoute.stateKey}
  ///
  /// {@macro StateRoute.shell.routeBuilder}
  ///
  /// {@macro StateRoute.path}
  factory DataStateRoute.popup(
    DataStateKey<D> stateKey, {
    required DataStateRouteBuilder<D> routeBuilder,
    DataRoutePath<D>? path,
  }) =>
      DataStateRoute<D>._((parent) {
        return createDataStateRouteConfig1<D>(
          parent,
          stateKey,
          routeBuilder,
          null,
          [StateDataResolver<D>(stateKey)],
          false,
          path,
          const [],
        );
      });

  /// Constructs a [DataStateRoute] for a parent state that provides common
  /// layout (i.e. a 'shell') wrapping a nested router that displays visuals for
  /// active descendant states.
  ///
  /// {@macro StateRoute.stateKey}
  ///
  /// A list of [routes] must be provided that determine the routing for
  /// descendant states of the parent state identfied by [stateKey].
  ///
  /// {@macro StateRoute.buildersSummary}
  ///
  /// {@macro StateRoute.shell.builderFunctions}
  ///
  /// {@macro StateRoute.path}
  ///
  /// {@macro StateRoute.shell.routerArgs}
  factory DataStateRoute.shell(
    DataStateKey<D> stateKey, {
    required List<StateRouteInfoBuilder> routes,
    ShellDataStateRouteBuilder<D>? routeBuilder,
    ShellDataStateRoutePageBuilder<D>? routePageBuilder,
    bool enableTransitions = false,
    DefaultScaffoldingBuilder? defaultScaffolding,
    DataRoutePath<D>? path,
  }) =>
      DataStateRoute<D>._((parent) {
        var childRouteConfigs = <StateRouteInfo>[];
        DescendantStatesRouter nestedRouter() => DescendantStatesRouter(
              key: ValueKey(stateKey),
              anchorKey: stateKey,
              routes: childRouteConfigs,
              enableTransitions: enableTransitions,
              defaultScaffolding: defaultScaffolding,
            );

        var config = createDataStateRouteConfig1<D>(
          parent,
          stateKey,
          routeBuilder != null
              ? (ctx, stateCtx, data) => routeBuilder(
                    ctx,
                    stateCtx,
                    nestedRouter(),
                    data,
                  )
              : null,
          routePageBuilder != null
              ? (buildContext, wrapPageContent) => routePageBuilder(
                  buildContext,
                  (buildPageContent) => wrapPageContent(
                      (context, stateContext, data) => buildPageContent(
                            context,
                            stateContext,
                            nestedRouter(),
                            data,
                          )))
              : null,
          [StateDataResolver<D>(stateKey)],
          false,
          path,
          routes,
        );
        childRouteConfigs.addAll(config.childRoutes);
        return config;
      });

  final CreateRouteConfig _createRouteConfig;

  @override
  StateRouteInfo buildRouteInfo(StateRouteInfo? parent) =>
      _createRouteConfig(parent);
}

/// {@macro DataStateRouteBuilder}
///
/// Additionally, the function is provided [ancestorData] that contains  a
/// data value obtained from an ancestor data state.
typedef DataStateRouteBuilder2<D, DAnc> = Widget Function(
  BuildContext context,
  StateRoutingContext stateContext,
  D data,
  DAnc ancestorData,
);

/// {@macro DataStateRoutePageBuilder}
typedef DataStateRoutePageBuilder2<D, DAnc> = Page<void> Function(
  BuildContext context,
  Widget Function(DataStateRouteBuilder2<D, DAnc> buildPageContent)
      wrapPageContent,
);

/// A route that creates visuals for a data state, using state data of type [D]
/// and [DAnc1] obtained from the data state, and an ancestor data state.
///
/// This route is used in a very similar manner as [DataStateRoute], with the
/// addition of providing the [DataStateKey] of the ancestor state whose data
/// should be obtained.
class DataStateRoute2<D, DAnc1> implements StateRouteInfoBuilder {
  DataStateRoute2._(this._createRouteConfig);

  /// Constructs a [DataStateRoute3].
  factory DataStateRoute2(
    DataStateKey<D> stateKey, {
    required DataStateKey<DAnc1> ancestorStateKey,
    DataStateRouteBuilder2<D, DAnc1>? routeBuilder,
    DataStateRoutePageBuilder2<D, DAnc1>? routePageBuilder,
    RoutePathInfo? path,
  }) =>
      DataStateRoute2._((parent) {
        return createDataStateRouteConfig2(
          parent,
          stateKey,
          routeBuilder,
          routePageBuilder,
          [
            StateDataResolver<D>(stateKey),
            StateDataResolver<DAnc1>(ancestorStateKey),
          ],
          false,
          path,
          const [],
        );
      });

  factory DataStateRoute2.popup(
    DataStateKey<D> stateKey, {
    required DataStateKey<DAnc1> ancestor1StateKey,
    required DataStateRouteBuilder2<D, DAnc1> routeBuilder,
  }) =>
      DataStateRoute2._((parent) {
        return createDataStateRouteConfig3(
          parent,
          stateKey,
          null,
          null,
          [
            StateDataResolver<D>(stateKey),
            StateDataResolver<DAnc1>(ancestor1StateKey),
          ],
          true,
          null,
          const [],
        );
      });

  final CreateRouteConfig _createRouteConfig;

  @override
  StateRouteInfo buildRouteInfo(StateRouteInfo? parent) =>
      _createRouteConfig(parent);
}

/// {@macro DataStateRouteBuilder}
///
/// Additionally, the function is provided [ancestor1Data] and [ancestor2Data]
/// that contain data values obtained from ancestor data states.
typedef DataStateRouteBuilder3<D, DAnc1, DAnc2> = Widget Function(
  BuildContext context,
  StateRoutingContext stateContext,
  D data,
  DAnc1 ancestor1Data,
  DAnc2 ancestor2Data,
);

/// {@macro DataStateRoutePageBuilder}
typedef DataStateRoutePageBuilder3<D, DAnc1, DAnc2> = Page<void> Function(
  BuildContext context,
  Widget Function(DataStateRouteBuilder3<D, DAnc1, DAnc2> buildPageContent)
      wrapPageContent,
);

/// A route that creates visuals for a data state, using state data of type [D],
/// [DAnc1] and [DAnc2] obtained from the data state, and two ancestor data
/// states.
///
/// This route is used in a very similar manner as [DataStateRoute], with the
/// addition of providing the [DataStateKey]s of the ancestor states whose data
/// should be obtained.
///
/// Note that there is no relationship implied between the ancestor states.
/// Either state may be an ancestor of the other.
class DataStateRoute3<D, DAnc1, DAnc2> implements StateRouteInfoBuilder {
  DataStateRoute3._(this._createRouteConfig);

  /// Constructs a [DataStateRoute3].
  factory DataStateRoute3(
    DataStateKey<D> stateKey, {
    required DataStateKey<DAnc1> ancestor1StateKey,
    required DataStateKey<DAnc2> ancestor2StateKey,
    DataStateRouteBuilder3<D, DAnc1, DAnc2>? routeBuilder,
    DataStateRoutePageBuilder3<D, DAnc1, DAnc2>? routePageBuilder,
    RoutePathInfo? path,
  }) =>
      DataStateRoute3._((parent) {
        return createDataStateRouteConfig3(
          parent,
          stateKey,
          routeBuilder,
          routePageBuilder,
          [
            StateDataResolver<D>(stateKey),
            StateDataResolver<DAnc1>(ancestor1StateKey),
            StateDataResolver<DAnc2>(ancestor2StateKey),
          ],
          false,
          path,
          const [],
        );
      });

  factory DataStateRoute3.popup(
    DataStateKey<D> stateKey, {
    required DataStateKey<DAnc1> ancestor1StateKey,
    required DataStateKey<DAnc2> ancestor2StateKey,
    required DataStateRouteBuilder3<D, DAnc1, DAnc2> routeBuilder,
  }) =>
      DataStateRoute3._((parent) {
        return createDataStateRouteConfig3(
          parent,
          stateKey,
          routeBuilder,
          null,
          [
            StateDataResolver<D>(stateKey),
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
  StateRouteInfo buildRouteInfo(StateRouteInfo? parent) =>
      _createRouteConfig(parent);
}
