import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/router_delegate.dart';
import 'package:tree_state_router/tree_state_router.dart';

class NestedStateMachineRouter extends StatelessWidget {
  /// Constructs a [NestedStateMachineRouter].
  const NestedStateMachineRouter({
    super.key,
    required this.machineStateKey,
    required this.routes,
    this.defaultPageBuilder,
    this.defaultScaffolding,
    this.enableTransitions = true,
  });

  /// {@macroNestedMachineRouterDelegate.machineStateKey}
  final DataStateKey<MachineTreeStateData> machineStateKey;

  /// The list of routes that can be materialized by this router.
  final List<StateRouteConfig> routes;

  /// {@macro TreeStateRouter.defaultScaffolding}
  final DefaultScaffoldingBuilder? defaultScaffolding;

  /// {@macro TreeStateRouter.defaultPageBuilder}
  final DefaultPageBuilder? defaultPageBuilder;

  /// {@macro TreeStateRouter.enableTransitions}
  final bool enableTransitions;

  //late final _routeConfigs = routes.map((r) => r.config).toList();

  @override
  Widget build(BuildContext context) {
    return Router(
      routerDelegate: NestedMachineRouterDelegate(
        machineStateKey: machineStateKey,
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
