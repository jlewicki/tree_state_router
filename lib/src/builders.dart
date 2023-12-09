import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/provider.dart';

/// A function that constructs widget that visualizes an active tree state in a state machine.
///
/// The function is provided the [currentState] of the tree state machine.
typedef TreeStateWidgetBuilder = Widget Function(
  BuildContext context,
  CurrentState currentState,
);

class TreeStateView extends StatelessWidget {
  const TreeStateView({
    super.key,
    required this.stateKey,
    required this.builder,
  });

  /// The state key of the tree state that is built by this builder.
  final StateKey stateKey;

  /// The function that produces the widget that visualizes the tree state.
  final TreeStateWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    var stateMachineInfo = TreeStateMachineProvider.of(context);

    if (stateMachineInfo == null) {
      Widget widget = Container();
      assert(() {
        widget = ErrorWidget.withDetails(
          message: 'Unable to build widget for tree state "$stateKey", '
              'because a state machine was not found in the widget tree.',
        );
        return true;
      }());
      return widget;
    }

    if (!stateMachineInfo.currentState.isInState(stateKey)) {
      Widget widget = Container();
      assert(() {
        widget = ErrorWidget.withDetails(
          message: 'Unable to build widget for tree state "$stateKey", '
              'because "$stateKey" is not an active state in the state machine.',
        );
        return true;
      }());
      return widget;
    }

    return builder(context, stateMachineInfo.currentState);
  }
}
