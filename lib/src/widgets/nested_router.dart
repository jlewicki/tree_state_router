import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/router_delegate.dart';
import 'package:tree_state_router/tree_state_router.dart';

/// A routing widget that provides visuals for the active states in a state tree, intended for use as
/// a descendant of a top-level [TreeStateRouter].
class NestedTreeStateRouter extends StatelessWidget {
  NestedTreeStateRouter({
    super.key,
    required this.parentStateKey,
    required this.routes,
    this.defaultPageBuilder,
    this.defaultScaffolding,
    this.enableTransitions = true,
  });

  /// {@macro NestedTreeStateRouterDelegate.parentKey}
  final StateKey parentStateKey;

  /// The list of routes that can be materialized by this router.
  final List<StateRouteConfigProvider> routes;

  /// {@macro TreeStateRouter.defaultScaffolding}
  final DefaultScaffoldingBuilder? defaultScaffolding;

  /// {@macro TreeStateRouter.defaultPageBuilder}
  final DefaultPageBuilder? defaultPageBuilder;

  /// {@macro TreeStateRouter.enableTransitions}
  final bool enableTransitions;

  late final _routeConfigs = routes.map((r) => r.config).toList();

  @override
  Widget build(BuildContext context) {
    return Router(
      routerDelegate: NestedTreeStateRouterDelegate(
        parentKey: parentStateKey,
        config: TreeStateRouterDelegateConfig(
          _routeConfigs,
          defaultPageBuilder: defaultPageBuilder,
          defaultScaffolding: defaultScaffolding,
          enableTransitions: enableTransitions,
        ),
      ),
    );
  }
}
