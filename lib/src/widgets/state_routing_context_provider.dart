import 'package:flutter/widgets.dart';
import 'package:tree_state_router/tree_state_router.dart';

/// Provides a [StateRoutingContext] value to descendant widgets.
class StateRoutingContextProvider extends StatelessWidget {
  const StateRoutingContextProvider({
    super.key,
    required this.routingContext,
    required this.child,
  });

  /// The current state of the state machine to be provided to descendant widgets.
  final StateRoutingContext routingContext;

  /// The widget below this widget in the tree.
  final Widget child;

  /// The data from the closest [StateRoutingContextProvider] instance that encloses the given context.
  static StateRoutingContext? of(BuildContext context) {
    var inheritedInfo = context
        .dependOnInheritedWidgetOfExactType<_InheritedStateMachineInfo>();
    return inheritedInfo?.routingInfo;
  }

  @override
  Widget build(BuildContext context) => _InheritedStateMachineInfo(
        routingInfo: routingContext,
        child: child,
      );
}

class _InheritedStateMachineInfo extends InheritedWidget {
  const _InheritedStateMachineInfo({
    required this.routingInfo,
    required super.child,
  });

  final StateRoutingContext routingInfo;

  @override
  bool updateShouldNotify(_InheritedStateMachineInfo old) {
    var changed = routingInfo != old.routingInfo;
    return changed;
  }
}
