import 'package:flutter/material.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'builder.dart';

/// {@template DataStateRouteBuilder}
/// A function that can build a widget providing a visualization of an active data state in a state
/// tree.
///
/// The function is provided a build [context], and a [stateContext] that describes the state to be
/// visualized, and the current [data] value for the data state.
/// {@endtemplate}
typedef DataStateRouteBuilder<D> = Widget Function(
  BuildContext context,
  StateRoutingContext stateContext,
  D data,
);

/// {@template DataStateRoutePageBuilder}
/// A function that can build a routing [Page] that provides a visualization of an active state in
/// a state tree.
///
/// The function is provided a build [context], and a [wrapPageContent] function that must be called
/// in order to wrap the contents of the route in a specialized widget that detects state
/// transitions and re-renders this route as necessary. The return value of the
/// [wrapPageContent] function should be used as the contents of the page.
///
/// ```dart
/// var routerConfig = TreeStateRouter(
///   routes: [
///     DataTreeStateRoute(
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
/// The builder functions are provided with a `data` argument that is the current data value of the
/// data state at the time the visuals are created. If the state data value is updated while a
/// message is processed by the state machine, the builder function will be called again by the router
/// with the updated data value.
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
class DataStateRoute<D> implements StateRouteConfigProvider {
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

  factory DataStateRoute.popup(
    DataStateKey<D> stateKey, {
    required DataStateRouteBuilder<D> routeBuilder,
  }) =>
      DataStateRoute<D>._((parent) {
        return createDataStateRouteConfig1<D>(
          parent,
          stateKey,
          routeBuilder,
          null,
          [StateDataResolver<D>(stateKey)],
          false,
          null,
          const [],
        );
      });

  factory DataStateRoute.shell(
    DataStateKey<D> stateKey, {
    required List<StateRouteConfigProvider> routes,
    ShellDataStateRouteBuilder<D>? routeBuilder,
    ShellDataStateRoutePageBuilder<D>? routePageBuilder,
    bool enableTransitions = false,
    DefaultScaffoldingBuilder? defaultScaffolding,
    DataRoutePath<D>? path,
  }) =>
      DataStateRoute<D>._((parent) {
        var childRouteConfigs = <StateRouteConfig>[];
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
  StateRouteConfig createConfig(StateRouteConfig? parent) =>
      _createRouteConfig(parent);

  // /// {@template DataStateRoute.stateKey}
  // /// Identifies the data tree state associated with this route.
  // /// {@endtemplate}
  // final DataStateKey<D> stateKey;

  // /// {@macro StateRoute.routeBuilder}
  // final DataStateRouteBuilder<D>? routeBuilder;

  // /// {@macro StateRoute.routePageBuilder}
  // final DataStateRoutePageBuilder<D>? routePageBuilder;

  // /// {@macro StateRoute.isPopup}
  // final bool isPopup;

  // /// {@macro StateRoute.path}
  // final DataRoutePath<D>? path;

  // /// {@macro StateRoute.childRoutes}
  // final List<StateRouteConfigProvider> childRoutes;

  // final List<StateRouteConfig> _childRouteConfigs;

  // late final List<StateDataResolver> _resolvers = [
  //   StateDataResolver<D>(stateKey)
  // ];
}

typedef DataStateRouteBuilder2<D, DAnc> = Widget Function(
  BuildContext context,
  StateRoutingContext stateContext,
  D data,
  DAnc ancestorData,
);

typedef DataStateRoutePageBuilder2<D, DAnc> = Page<void> Function(
  BuildContext context,
  Widget Function(DataStateRouteBuilder2<D, DAnc> buildPageContent)
      wrapPageContent,
);

/// A route that creates visuals for a data state, using state data of type [D] and [DAnc1]
/// obtained from the data state, and an ancestor data state.
///
/// This route is used in a very similar manner as [DataStateRoute], with the addition of providing
/// the [DataStateKey] of the ancestor state whose data should be obtained.
class DataStateRoute2<D, DAnc1> implements StateRouteConfigProvider {
  DataStateRoute2._(this._createRouteConfig);

  /// Constructs a [DataStateRoute3].
  factory DataStateRoute2(
    DataStateKey<D> stateKey, {
    required DataStateKey<DAnc1> ancestorStateKey,
    DataStateRouteBuilder2<D, DAnc1>? routeBuilder,
    DataStateRoutePageBuilder2<D, DAnc1>? routePageBuilder,
    RoutePathConfig? path,
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
  StateRouteConfig createConfig(StateRouteConfig? parent) =>
      _createRouteConfig(parent);
}

typedef DataStateRouteBuilder3<D, DAnc1, DAnc2> = Widget Function(
  BuildContext context,
  StateRoutingContext stateContext,
  D data,
  DAnc1 ancestor1Data,
  DAnc2 ancestor2Data,
);

typedef DataStateRoutePageBuilder3<D, DAnc1, DAnc2> = Page<void> Function(
  BuildContext context,
  Widget Function(DataStateRouteBuilder3<D, DAnc1, DAnc2> buildPageContent)
      wrapPageContent,
);

/// A route that creates visuals for a data state, using state data of type [D], [DAnc1] and [DAnc2]
/// obtained from the data state, and two ancestor data states.
///
/// This route is used in a very similar manner as [DataStateRoute], with the addition of providing
/// the [DataStateKey]s of the ancestor states whose data should be obtained.
///
/// Note that there is no relationship implied between the ancestor states. Either state may be an
/// ancestor of the other.
class DataStateRoute3<D, DAnc1, DAnc2> implements StateRouteConfigProvider {
  DataStateRoute3._(this._createRouteConfig);

  /// Constructs a [DataStateRoute3].
  factory DataStateRoute3(
    DataStateKey<D> stateKey, {
    required DataStateKey<DAnc1> ancestor1StateKey,
    required DataStateKey<DAnc2> ancestor2StateKey,
    DataStateRouteBuilder3<D, DAnc1, DAnc2>? routeBuilder,
    DataStateRoutePageBuilder3<D, DAnc1, DAnc2>? routePageBuilder,
    RoutePathConfig? path,
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
  StateRouteConfig createConfig(StateRouteConfig? parent) =>
      _createRouteConfig(parent);
}

  // /// {@macro DataStateRoute.stateKey}
  // final DataStateKey<D> stateKey;

  // /// {@macro StateRoute2.ancestor1StateKey}
  // final DataStateKey<DAnc1> ancestor1StateKey;

  // /// {@macro StateRoute2.ancestor1StateKey}
  // final DataStateKey<DAnc2> ancestor2StateKey;

  // /// {@macro StateRoute.routeBuilder}
  // ///
  // /// When called, this function is provided the current [D], [DAnc1] and [DAnc2] values obtained
  // /// from the data state, and the two ancestor states.
  // final DataStateRouteBuilder3<D, DAnc1, DAnc2>? routeBuilder;

  // /// {@macro StateRoute.routePageBuilder}
  // ///
  // /// When called, this function is provided the current [D], [DAnc1] and [DAnc2] values obtained
  // /// from the data state, and the two ancestor states.
  // final DataStateRoutePageBuilder3<D, DAnc1, DAnc2>? routePageBuilder;

  // /// {@macro StateRoute.isPopup}
  // final bool isPopup;

  // /// {@macro StateRoute.path}
  // final RoutePathConfig? path;

  // /// {@macro StateRoute.childRoutes}
  // final List<StateRouteConfigProvider> childRoutes;

  // late final List<StateDataResolver> _resolvers = [
  //   StateDataResolver<D>(stateKey),
  //   StateDataResolver<DAnc1>(ancestor1StateKey),
  //   StateDataResolver<DAnc2>(ancestor2StateKey)
  // ];


