import 'package:tree_state_machine/tree_state_machine.dart';

/// The [Transition.metadata] key used to record that a transition was sourced
/// from [MessageContextRoutingExtensions.pushGoTo].
const isPushTransitionKey = '[TreeStateRouter].[IsPush]';

/// The [Transition.metadata] key used to record the message that should be
/// posted to the state machine, when a transition sourced from
/// [MessageContextRoutingExtensions.pushGoTo] is popped.
const popMessageKey = '[TreeStateRouter].[PopMessage]';

/// Extensions on [MessageContext] related to routing.
extension MessageContextRoutingExtensions on MessageContext {
  TransitionMessageResult pushGoTo(
    StateKey targetState, {
    required Object popMessage,
    TransitionHandler? transitionAction,
    Object? payload,
    bool reenterTarget = false,
    Map<String, Object> metadata = const {},
  }) {
    var metadata_ = {
      ...metadata,
      isPushTransitionKey: true,
      popMessageKey: popMessage,
    };
    return goTo(
      targetState,
      transitionAction: transitionAction,
      payload: payload,
      reenterTarget: reenterTarget,
      metadata: metadata_,
    );
  }
}

/// Extensions on [Transition] related to routing.
extension TransitionRoutingExtensions on Transition {
  /// Indicates if this transition was sourced from
  /// [MessageContextRoutingExtensions.pushGoTo].
  bool get isPushTransition {
    var isPushTransition_ = metadata[isPushTransitionKey];
    return isPushTransition_ != null && isPushTransition_ is bool
        ? isPushTransition_
        : false;
  }

  /// The message that should be posted to the state machine, when a transition
  /// sourced from [MessageContextRoutingExtensions.pushGoTo] is popped.
  Object? get popMessage => metadata[popMessageKey];
}
