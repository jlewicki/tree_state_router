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
  DataStateRoute._(
    this.stateKey, {
    this.routeBuilder,
    this.routePageBuilder,
    this.isPopup = false,
    this.path,
  });

  /// Constructs a [DataStateRoute].
  DataStateRoute(
    this.stateKey, {
    this.routeBuilder,
    this.routePageBuilder,
    this.path,
  }) : isPopup = false;

  factory DataStateRoute.popup(
    DataStateKey<D> stateKey, {
    required DataStateRouteBuilder<D> routeBuilder,
  }) =>
      DataStateRoute<D>._(stateKey, routeBuilder: routeBuilder, isPopup: true);

  factory DataStateRoute.shell(
    DataStateKey<D> stateKey, {
    required List<StateRouteConfigProvider> routes,
    ShellDataStateRouteBuilder<D>? routeBuilder,
    ShellDataStateRoutePageBuilder<D>? routePageBuilder,
    bool enableTransitions = false,
    DefaultScaffoldingBuilder? defaultScaffolding,
  }) {
    var nestedRouter = NestedTreeStateRouter(
      key: ValueKey(stateKey),
      parentStateKey: stateKey,
      routes: routes,
      enableTransitions: enableTransitions,
      defaultScaffolding: defaultScaffolding,
    );
    return DataStateRoute<D>._(
      stateKey,
      routeBuilder: routeBuilder != null
          ? (ctx, stateCtx, data) => routeBuilder(
                ctx,
                stateCtx,
                nestedRouter,
                data,
              )
          : null,
      routePageBuilder: routePageBuilder != null
          ? (buildContext, wrapPageContent) => routePageBuilder(
              buildContext,
              (buildPageContent) => wrapPageContent(
                  (context, stateContext, data) => buildPageContent(
                        context,
                        stateContext,
                        nestedRouter,
                        data,
                      )))
          : null,
      isPopup: false,
    );
  }

  /// {@template DataStateRoute.stateKey}
  /// Identifies the data tree state associated with this route.
  /// {@endtemplate}
  final DataStateKey<D> stateKey;

  /// {@macro StateRoute.routeBuilder}
  final DataStateRouteBuilder<D>? routeBuilder;

  /// {@macro StateRoute.routePageBuilder}
  final DataStateRoutePageBuilder<D>? routePageBuilder;

  /// {@macro StateRoute.isPopup}
  final bool isPopup;

  /// {@macro StateRoute.path}
  final RoutePathConfig? path;

  late final List<StateDataResolver> _resolvers = [
    StateDataResolver<D>(stateKey)
  ];

  @override
  late final config = createDataStateRouteConfig1(
    stateKey,
    routeBuilder,
    routePageBuilder,
    _resolvers,
    isPopup,
    path,
  );
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

/// A route that creates visuals for a data state, using state data of type [D] and [DAnc]
/// obtained from the data state, and an ancestor data state.
///
/// This route is used in a very similar manner as [DataStateRoute], with the addition of providing
/// the [DataStateKey] of the ancestor state whose data should be obtained.
class DataStateRoute2<D, DAnc> implements StateRouteConfigProvider {
  DataStateRoute2._(
    this.stateKey, {
    required this.ancestorStateKey,
    this.routeBuilder,
    this.routePageBuilder,
    this.isPopup = false,
    this.path,
  });

  /// Constructs a [DataStateRoute2].
  DataStateRoute2(
    this.stateKey, {
    required this.ancestorStateKey,
    this.routeBuilder,
    this.routePageBuilder,
    this.path,
  }) : isPopup = false;

  factory DataStateRoute2.popup(
    DataStateKey<D> stateKey, {
    required DataStateKey<DAnc> ancestorStateKey,
    required DataStateRouteBuilder2<D, DAnc> routeBuilder,
  }) =>
      DataStateRoute2<D, DAnc>._(
        stateKey,
        ancestorStateKey: ancestorStateKey,
        routeBuilder: routeBuilder,
        isPopup: true,
      );

  /// {@macro DataStateRoute.stateKey}
  final DataStateKey<D> stateKey;

  /// {@macro StateRoute1.ancestorStateKey}
  final DataStateKey<DAnc> ancestorStateKey;

  /// {@macro StateRoute.routeBuilder}
  ///
  /// When called, this function is provided the current [D] and [DAnc] values obtained from the
  /// data state and the ancestor state.
  final DataStateRouteBuilder2<D, DAnc>? routeBuilder;

  /// {@macro StateRoute.routePageBuilder}
  ///
  /// When called, this function is provided the current [D] and [DAnc] values obtained from the
  /// data state and the ancestor state.
  final DataStateRoutePageBuilder2<D, DAnc>? routePageBuilder;

  /// {@macro StateRoute.isPopup}
  final bool isPopup;

  /// {@macro StateRoute.path}
  final RoutePathConfig? path;

  late final List<StateDataResolver> _resolvers = [
    StateDataResolver<D>(stateKey),
    StateDataResolver<DAnc>(ancestorStateKey)
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
  DataStateRoute3._(
    this.stateKey, {
    required this.ancestor1StateKey,
    required this.ancestor2StateKey,
    this.routeBuilder,
    this.routePageBuilder,
    this.isPopup = false,
    this.path,
  });

  /// Constructs a [DataStateRoute3].
  DataStateRoute3(
    this.stateKey, {
    required this.ancestor1StateKey,
    required this.ancestor2StateKey,
    this.routeBuilder,
    this.routePageBuilder,
    this.path,
  }) : isPopup = false;

  factory DataStateRoute3.popup(
    DataStateKey<D> stateKey, {
    required DataStateKey<DAnc1> ancestor1StateKey,
    required DataStateKey<DAnc2> ancestor2StateKey,
    required DataStateRouteBuilder3<D, DAnc1, DAnc2> routeBuilder,
  }) =>
      DataStateRoute3<D, DAnc1, DAnc2>._(
        stateKey,
        ancestor1StateKey: ancestor1StateKey,
        ancestor2StateKey: ancestor2StateKey,
        routeBuilder: routeBuilder,
        isPopup: true,
      );

  /// {@macro DataStateRoute.stateKey}
  final DataStateKey<D> stateKey;

  /// {@macro StateRoute2.ancestor1StateKey}
  final DataStateKey<DAnc1> ancestor1StateKey;

  /// {@macro StateRoute2.ancestor1StateKey}
  final DataStateKey<DAnc2> ancestor2StateKey;

  /// {@macro StateRoute.routeBuilder}
  ///
  /// When called, this function is provided the current [D], [DAnc1] and [DAnc2] values obtained
  /// from the data state, and the two ancestor states.
  final DataStateRouteBuilder3<D, DAnc1, DAnc2>? routeBuilder;

  /// {@macro StateRoute.routePageBuilder}
  ///
  /// When called, this function is provided the current [D], [DAnc1] and [DAnc2] values obtained
  /// from the data state, and the two ancestor states.
  final DataStateRoutePageBuilder3<D, DAnc1, DAnc2>? routePageBuilder;

  /// {@macro StateRoute.isPopup}
  final bool isPopup;

  /// {@macro StateRoute.path}
  final RoutePathConfig? path;

  late final List<StateDataResolver> _resolvers = [
    StateDataResolver<D>(stateKey),
    StateDataResolver<DAnc1>(ancestor1StateKey),
    StateDataResolver<DAnc2>(ancestor2StateKey)
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
