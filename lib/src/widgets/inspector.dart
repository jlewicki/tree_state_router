import 'package:flutter/material.dart';
import 'package:tree_state_router/src/widgets/state_machine_events.dart';
import 'package:tree_state_router/tree_state_router.dart';

/// A widget that displays diagnostic information about a tree state machine.
///
/// The state machine is obtained with [TreeStateMachineProvider.of], and consequently find the
/// closest machine in the ancestor hierarchy.
class StateTreeInspector extends StatefulWidget {
  const StateTreeInspector({super.key, required this.child});

  // Content to adorn with diagnostiic information.
  final Widget child;

  @override
  State<StateTreeInspector> createState() => _StateTreeInspectorState();
}

class _StateTreeInspectorState extends State<StateTreeInspector> {
  @override
  Widget build(BuildContext context) {
    var info = TreeStateMachineProvider.of(context);
    return info != null
        ? TreeStateMachineEvents(
            // Re-render on transitions, so that correct active states are displayed
            onTransition: (_, __) => setState(() {}),
            child: Stack(
              children: [
                widget.child,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.blueGrey.shade200.withOpacity(0.5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (info.currentState.stateMachine.label != null)
                            Text(
                                'State Machine: ${info.currentState.stateMachine.label}'),
                          Text(
                              "Active States: ${info.currentState.activeStates.join(' -> ')}"),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ))
        : widget.child;
  }
}
