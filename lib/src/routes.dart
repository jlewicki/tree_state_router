import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/builders.dart';

/// TBD: This will contain routing information parsed from the current URI.
class TreeStateRoutingState {}

class TreeStateRoutingContext {
  TreeStateRoutingContext(this.currentState);
  final CurrentState currentState;
  final TreeStateRoutingState routingState = TreeStateRoutingState();
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

/// A function that can widget provides a visualization of an active data state in a state tree.
///
/// The function is provided a build [context], a [stateContext] that describes the state to be
/// visualized, and the current state data
typedef DataTreeStateRouteBuilder<D> = Widget Function(
  BuildContext context,
  TreeStateRoutingContext stateContext,
  D data,
);

typedef DataTreeStateRouteBuilder2<D, DAnc> = Widget Function(
  BuildContext context,
  TreeStateRoutingContext stateContext,
  D data,
  DAnc ancestorData,
);

typedef DataTreeStateRouteBuilder3<D, DAnc1, DAnc2> = Widget Function(
  BuildContext context,
  TreeStateRoutingContext stateContext,
  D data,
  DAnc1 ancestorData1,
  DAnc2 ancestorData2,
);

/// A route associated with a state in a state tree, which is used to visually display the tree
/// state in a [Navigator] widget.
///
/// When the tree state identified by [stateKey] is an active state in a [TreeStateMachine], the
/// [routePageBuilder] or [routeBuilder] for this route is used to produce the widget that
/// visualizes the state.
///
/// Note that only one of [routePageBuilder] or [routeBuilder] can be provided.
class TreeStateRoute {
  TreeStateRoute(
    this.stateKey, {
    this.routePageBuilder,
    this.routeBuilder,
  })  : assert(routePageBuilder != null || routeBuilder != null,
            "One of routePageBuilder or routeBuilder must be provided"),
        assert(!(routePageBuilder != null && routeBuilder != null),
            "Only one of routePageBuilder or routeBuilder can be provided");

  /// The state key identifying the tree state associated with this route.
  final StateKey stateKey;

  /// {@macro TreeStateRoutePageBuilder}
  final TreeStateRoutePageBuilder? routePageBuilder;

  /// {@macro TreeStateRouteBuilder}
  ///
  /// If provided, tree state router will choose an appropriate [Page] type based on the application
  /// typoe (Material, Cupertino, etc.).
  final TreeStateRouteBuilder? routeBuilder;
}

/// A route associated with a data state in a state tree, which is used to visually display the tree
/// state in a [Navigator] widget.
///
/// When the tree state identified by [stateKey] is an active state in a [TreeStateMachine], the
/// [routePageBuilder] or [routeBuilder] for this route is used to produce the widget that
/// visualizes the state.
///
/// Additionally, if the data value in the data state is updated, the [routePageBuilder] or
/// [routeBuilder] will be called with the update value.
class DataTreeStateRoute<D> extends TreeStateRoute {
  DataTreeStateRoute(
    DataStateKey<D> super.stateKey, {
    DataTreeStateRouteBuilder<D>? dataRouteBuilder,
  }) : super(
            routeBuilder: dataRouteBuilder == null
                ? null
                : (context, stateContext) {
                    return DataTreeStateBuilder<D>(
                      stateKey: stateKey,
                      builder: (context, _, stateData) {
                        return dataRouteBuilder.call(context, stateContext, stateData);
                      },
                    );
                  });
}

class DataTreeStateRoute2<D, DAnc> extends TreeStateRoute {
  DataTreeStateRoute2(
    DataStateKey<D> super.stateKey, {
    DataTreeStateRouteBuilder2<D, DAnc>? dataRouteBuilder,
  }) : super(
          routeBuilder: dataRouteBuilder == null
              ? null
              : (context, stateContext) {
                  return DataTreeStateBuilder2<D, DAnc>(
                    stateKey: stateKey,
                    builder: (context, _, stateData, ancData) {
                      return dataRouteBuilder.call(context, stateContext, stateData, ancData);
                    },
                  );
                },
        );
}

class DataTreeStateRoute3<D, DAnc, DAnc2> extends TreeStateRoute {
  DataTreeStateRoute3(
    DataStateKey<D> super.stateKey, {
    DataTreeStateRouteBuilder3<D, DAnc, DAnc2>? dataRouteBuilder,
  }) : super(
          routeBuilder: dataRouteBuilder == null
              ? null
              : (context, stateContext) {
                  return DataTreeStateBuilder3<D, DAnc, DAnc2>(
                    stateKey: stateKey,
                    builder: (context, _, stateData, ancData, ancData2) {
                      return dataRouteBuilder.call(
                          context, stateContext, stateData, ancData, ancData2);
                    },
                  );
                },
        );
}
