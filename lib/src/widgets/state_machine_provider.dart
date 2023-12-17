import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';

/// Provides information about a [TreeStateMachine] to widgets, as returned by
/// [TreeStateMachineProvider.of].
class TreeStateMachineInfo {
  TreeStateMachineInfo(this.currentState);

  /// The current state of a [TreeStateMachine].
  final CurrentState currentState;
}

/// Provides a [TreeStateMachineInfo] value to descendant widgets.
class TreeStateMachineProvider extends StatelessWidget {
  const TreeStateMachineProvider({
    super.key,
    required this.currentState,
    required this.child,
  });

  /// The current state of the state machine to be provided to descendant widgets.
  final CurrentState currentState;

  /// The widget below this widget in the tree.
  final Widget child;

  /// The data from the closest [TreeStateMachineProvider] instance that encloses the given context.
  static TreeStateMachineInfo? of(BuildContext context) {
    var inheritedInfo = context
        .dependOnInheritedWidgetOfExactType<_InheritedStateMachineInfo>();
    return inheritedInfo != null
        ? TreeStateMachineInfo(inheritedInfo.currentState)
        : null;
  }

  @override
  Widget build(BuildContext context) => _InheritedStateMachineInfo(
        currentState: currentState,
        child: child,
      );
}

class _InheritedStateMachineInfo extends InheritedWidget {
  const _InheritedStateMachineInfo({
    required this.currentState,
    required super.child,
  });

  final CurrentState currentState;

  @override
  bool updateShouldNotify(_InheritedStateMachineInfo old) {
    var changed = currentState != old.currentState;
    return changed;
  }
}
