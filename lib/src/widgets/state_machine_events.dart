import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';

// A widget for receiving notifications from a [TreeStateMachine].
///
/// The state machine providing the events is obtained using [TreeStateMachineProvider.of].
class TreeStateMachineEvents extends StatefulWidget {
  const TreeStateMachineEvents({
    super.key,
    required this.child,
    this.transitionRootKey,
    this.onTransition,
    this.onFailedMessage,
  });

  /// The widget below this widget in the tree.
  final Widget child;

  /// Optional state key indicating a state that is used as a root for transition events.
  ///
  /// If provided, [onTransition] will be called only for transitions that occur between states that
  /// are desecendant of the transition root.
  final StateKey? transitionRootKey;

  /// Called when a state transition has occurred within the state machine.
  final void Function(CurrentState, Transition)? onTransition;

  /// Called when an error occurs when the state machine processes a message.
  final void Function(CurrentState, FailedMessage)? onFailedMessage;

  @override
  State createState() => _TreeStateMachineEventsState();
}

class _TreeStateMachineEventsState extends State<TreeStateMachineEvents> {
  StreamSubscription? _transitionSubscription;
  StreamSubscription? _errorSubscription;

  @override
  void didUpdateWidget(TreeStateMachineEvents oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onTransition != oldWidget.onTransition ||
        widget.onFailedMessage != oldWidget.onFailedMessage ||
        widget.transitionRootKey != oldWidget.transitionRootKey) {
      _unsubscribe();
      _subscribe();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _unsubscribe();
    _subscribe();
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _subscribe() {
    var stateMachineContext = TreeStateMachineProvider.of(context);
    if (stateMachineContext == null) {
      return;
    }

    var currentState = stateMachineContext.currentState;
    var stateMachine = currentState.stateMachine;

    if (widget.onFailedMessage != null) {
      _errorSubscription = stateMachine.failedMessages
          .listen((error) => widget.onFailedMessage!(currentState, error));
    }

    if (widget.onTransition != null) {
      var transitions = widget.transitionRootKey != null
          ? stateMachine.transitions.where((t) => !t.exitPath.contains(widget.transitionRootKey))
          : stateMachine.transitions;
      _transitionSubscription =
          transitions.listen((trans) => widget.onTransition!(currentState, trans));
    }
  }

  void _unsubscribe() {
    _transitionSubscription?.cancel();
    _errorSubscription?.cancel();
  }
}
