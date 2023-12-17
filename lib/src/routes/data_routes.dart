import 'package:flutter/material.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'builder.dart';

/// {@template DataStateRouteBuilder}
/// A function that can build a widget providing a visualization of an active data state in a state tree.
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
  });

  /// Constructs a [DataStateRoute].
  DataStateRoute(
    this.stateKey, {
    this.routeBuilder,
    this.routePageBuilder,
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

  /// Identifies the data tree state associated with this route.
  final DataStateKey<D> stateKey;

  /// {@macro StateRoute.routeBuilder}
  final DataStateRouteBuilder<D>? routeBuilder;

  /// {@macro StateRoute.routePageBuilder}
  final DataStateRoutePageBuilder<D>? routePageBuilder;

  /// {@macro StateRoute.isPopup}
  final bool isPopup;

  late final List<StateDataResolver> _resolvers = [
    StateDataResolver<D>(stateKey)
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
                (buildPageContent) =>
                    _createDataTreeStateBuilder(stateContext, buildPageContent),
              )
          : null,
      isPopup: isPopup,
      dependencies: _resolvers.map((e) => e.stateKey!).toList());

  DataStateBuilder _createDataTreeStateBuilder(
    StateRoutingContext stateContext,
    DataStateRouteBuilder<D> buildPageContent,
  ) {
    return DataStateBuilder(
      ValueKey(stateKey),
      stateKey,
      _resolvers,
      (context, dataList, currentState) => buildPageContent(
        context,
        stateContext,
        dataList.getAs<D>(0),
      ),
    );
  }
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

class DataStateRoute2<D, DAnc> implements StateRouteConfigProvider {
  DataStateRoute2._(
    this.stateKey, {
    required this.ancestorStateKey,
    this.routeBuilder,
    this.routePageBuilder,
    this.isPopup = false,
  });

  DataStateRoute2(
    this.stateKey, {
    required this.ancestorStateKey,
    this.routeBuilder,
    this.routePageBuilder,
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

  final DataStateKey<D> stateKey;
  final DataStateKey<DAnc> ancestorStateKey;
  final DataStateRouteBuilder2<D, DAnc>? routeBuilder;
  final DataStateRoutePageBuilder2<D, DAnc>? routePageBuilder;
  final bool isPopup;
  late final List<StateDataResolver> _resolvers = [
    StateDataResolver<D>(stateKey),
    StateDataResolver<DAnc>(ancestorStateKey)
  ];

  @override
  late final config = StateRouteConfig(
    stateKey,
    routeBuilder: routeBuilder != null
        ? (context, stateContext) =>
            _createDataTreeStateBuilder(stateContext, routeBuilder!)
        : null,
    routePageBuilder: routePageBuilder != null
        ? (context, stateContext) => routePageBuilder!.call(
              context,
              (buildPageContent) =>
                  _createDataTreeStateBuilder(stateContext, buildPageContent),
            )
        : null,
    isPopup: isPopup,
  );

  DataStateBuilder _createDataTreeStateBuilder(
    StateRoutingContext stateContext,
    DataStateRouteBuilder2<D, DAnc> buildPageContent,
  ) {
    return DataStateBuilder(
      ValueKey(stateKey),
      stateKey,
      _resolvers,
      (context, dataList, currentState) => buildPageContent(
        context,
        stateContext,
        dataList.getAs<D>(0),
        dataList.getAs<DAnc>(1),
      ),
    );
  }
}

typedef DataTreeStateRouteBuilder3<D, DAnc1, DAnc2> = Widget Function(
  BuildContext context,
  StateRoutingContext stateContext,
  D data,
  DAnc1 ancestor1Data,
  DAnc2 ancestor2Data,
);

typedef DataTreeStateRoutePageBuilder3<D, DAnc1, DAnc2> = Page<void> Function(
  BuildContext context,
  Widget Function(DataTreeStateRouteBuilder3<D, DAnc1, DAnc2> buildPageContent)
      wrapPageContent,
);

class DataTreeStateRoute3<D, DAnc1, DAnc2> implements StateRouteConfigProvider {
  DataTreeStateRoute3._(
    this.stateKey, {
    required this.ancestor1StateKey,
    required this.ancestor2StateKey,
    this.routeBuilder,
    this.routePageBuilder,
    this.isPopup = false,
  });

  DataTreeStateRoute3(
    this.stateKey, {
    required this.ancestor1StateKey,
    required this.ancestor2StateKey,
    this.routeBuilder,
    this.routePageBuilder,
  }) : isPopup = false;

  factory DataTreeStateRoute3.popup(
    DataStateKey<D> stateKey, {
    required DataStateKey<DAnc1> ancestor1StateKey,
    required DataStateKey<DAnc2> ancestor2StateKey,
    required DataTreeStateRouteBuilder3<D, DAnc1, DAnc2> routeBuilder,
  }) =>
      DataTreeStateRoute3<D, DAnc1, DAnc2>._(
        stateKey,
        ancestor1StateKey: ancestor1StateKey,
        ancestor2StateKey: ancestor2StateKey,
        routeBuilder: routeBuilder,
        isPopup: true,
      );

  final DataStateKey<D> stateKey;
  final DataStateKey<DAnc1> ancestor1StateKey;
  final DataStateKey<DAnc2> ancestor2StateKey;
  final DataTreeStateRouteBuilder3<D, DAnc1, DAnc2>? routeBuilder;
  final DataTreeStateRoutePageBuilder3<D, DAnc1, DAnc2>? routePageBuilder;
  final bool isPopup;
  late final List<StateDataResolver> _resolvers = [
    StateDataResolver<D>(stateKey),
    StateDataResolver<DAnc1>(ancestor1StateKey),
    StateDataResolver<DAnc2>(ancestor2StateKey)
  ];

  @override
  late final config = StateRouteConfig(
    stateKey,
    routeBuilder: routeBuilder != null
        ? (context, stateContext) =>
            _createDataTreeStateBuilder(stateContext, routeBuilder!)
        : null,
    routePageBuilder: routePageBuilder != null
        ? (context, stateContext) => routePageBuilder!.call(
              context,
              (buildPageContent) =>
                  _createDataTreeStateBuilder(stateContext, buildPageContent),
            )
        : null,
    isPopup: isPopup,
  );

  DataStateBuilder _createDataTreeStateBuilder(
    StateRoutingContext stateContext,
    DataTreeStateRouteBuilder3<D, DAnc1, DAnc2> buildPageContent,
  ) {
    return DataStateBuilder(
      ValueKey(stateKey),
      stateKey,
      _resolvers,
      (context, dataList, currentState) => buildPageContent(
        context,
        stateContext,
        dataList.getAs<D>(0),
        dataList.getAs<DAnc1>(1),
        dataList.getAs<DAnc2>(2),
      ),
    );
  }
}
