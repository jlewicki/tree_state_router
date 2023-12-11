import 'package:flutter/widgets.dart';
import 'package:tree_state_router/src/router_config.dart';
import 'package:tree_state_router/src/router_delegate.dart';
import 'package:tree_state_router/src/routes.dart';

/// A routing widget that provides visuals for the active states in a state tree, intended for use as
/// a descendant of a top-level [TreeStateRouter].
class NestedStateTreeRouter extends StatelessWidget {
  const NestedStateTreeRouter({
    super.key,
    required this.routes,
    this.defaultPageBuilder,
    this.defaultScaffolding,
    this.enableTransitions = true,
  });

  /// The list of routes that can be materialized by this router.
  final List<TreeStateRoute> routes;

  /// {@macro defaultScaffolding}
  final DefaultScaffoldingBuilder? defaultScaffolding;

  /// {@macro defaultPageBuilder}
  final DefaultPageBuilder? defaultPageBuilder;

  /// {@macro enableTransitions}
  final bool enableTransitions;

  @override
  Widget build(BuildContext context) {
    return Router(
      routerDelegate: NestedTreeStateRouterDelegate(
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
