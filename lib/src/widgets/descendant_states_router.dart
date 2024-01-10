import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/router_delegate.dart';
import 'package:tree_state_router/tree_state_router.dart';

/// A routing widget that provides visuals for the active states in a state tree, intended for use as
/// a descendant of a top-level [TreeStateRouter].
///
/// While it is possible to include this widget directly in a widget tree, nested routing is more
/// commonly implemented with [StateRoute.shell] or [DataStateRoute.shell], which will implicitly
/// construct [DescendantStatesRouter].
class DescendantStatesRouter extends StatelessWidget {
  /// Constructs a [DescendantStatesRouter].
  const DescendantStatesRouter({
    super.key,
    required this.anchorKey,
    required this.routes,
    this.defaultPageBuilder,
    this.defaultScaffolding,
    this.enableTransitions = true,
  });

  /// {@macro NestedTreeStateRouterDelegate.anchorKey}
  final StateKey anchorKey;

  /// The list of routes that can be materialized by this router.
  final List<StateRouteConfig> routes;

  /// {@macro TreeStateRouter.defaultScaffolding}
  final DefaultScaffoldingBuilder? defaultScaffolding;

  /// {@macro TreeStateRouter.defaultPageBuilder}
  final DefaultPageBuilder? defaultPageBuilder;

  /// {@macro TreeStateRouter.enableTransitions}
  final bool enableTransitions;

  @override
  Widget build(BuildContext context) {
    return Router(
      routerDelegate: DescendantStatesRouterDelegate(
        anchorKey: anchorKey,
        config: TreeStateRouterDelegateConfig(
          routes,
          defaultPageBuilder: defaultPageBuilder,
          defaultScaffolding: defaultScaffolding,
          enableTransitions: enableTransitions,
        ),
      ),
    );
  }
}
