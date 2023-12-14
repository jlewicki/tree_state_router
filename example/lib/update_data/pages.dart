import 'package:flutter/material.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'state_tree.dart';

Widget countingPage(
  BuildContext ctx,
  TreeStateRoutingContext stateCtx,
  CounterData data,
) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        'Counter: ${data.counter}',
        style: const TextStyle(fontSize: 24),
      ),
      _button(
        'Increment',
        () => stateCtx.currentState.post(Messages.increment),
      ),
      _button(
        'Decrement',
        () => stateCtx.currentState.post(Messages.decrement),
      ),
      _button('Restart', () async {
        await stateCtx.currentState.stateMachine.stop();
        await stateCtx.currentState.stateMachine.start();
      })
    ],
  );
}

Widget _button(String text, void Function() onPressed) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    ),
  );
}
