import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/widgets/state_machine_events.dart';

/// A widget that will call a builder function to display any errors that occur within a
/// [TreeStateMachine] as it processes messages.
class StateMachineErrorBuilder extends StatefulWidget {
  const StateMachineErrorBuilder({
    super.key,
    required this.errorBuilder,
    required this.child,
  });

  /// The widget do display when no errors have occurred.
  final Widget child;

  /// The builder function that is called when an error has occured when the state machine processed
  /// a message.
  final Widget Function(BuildContext, FailedMessage, CurrentState) errorBuilder;

  @override
  State<StateMachineErrorBuilder> createState() =>
      _StateMachineErrorBuilderState();
}

class _StateMachineErrorBuilderState extends State<StateMachineErrorBuilder> {
  FailedMessage? _failedMessage;
  CurrentState? _currentState;

  @override
  Widget build(BuildContext context) {
    return TreeStateMachineEvents(
      onFailedMessage: _onFailedMessage,
      child: _failedMessage != null
          ? widget.errorBuilder(context, _failedMessage!, _currentState!)
          : widget.child,
    );
  }

  void _onFailedMessage(
    CurrentState currentState,
    FailedMessage failedMessage,
  ) {
    setState(() {
      _failedMessage = failedMessage;
      _currentState = currentState;
    });
  }
}
