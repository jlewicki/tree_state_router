import 'package:flutter/material.dart';
import 'package:tree_state_router/src/provider.dart';

class StateTreeInspector extends StatelessWidget {
  const StateTreeInspector({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    var info = TreeStateMachineProvider.of(context);
    if (info != null) {
      return Column(
        children: [
          Container(
              padding: const EdgeInsets.all(8),
              color: Colors.blueGrey.shade200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (info.currentState.stateMachine.label != null)
                    Text('State Machine: ${info.currentState.stateMachine.label}'),
                  Text("Active States: ${info.currentState.activeStates.join(' -> ')}"),
                ],
              )),
          Expanded(child: child),
        ],
      );
    }
    return const Placeholder();
  }
}
