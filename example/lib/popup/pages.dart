import 'package:flutter/material.dart';
import 'package:tree_state_router/tree_state_router.dart';
import '../../helpers/helpers.dart';
import 'state_tree.dart';

Widget viewCounterPage(
  BuildContext ctx,
  StateRoutingContext stateCtx,
  CounterData data,
) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text('Counter Value: ${data.counter}'),
        button('Edit', () => stateCtx.currentState.post(Messages.edit)),
      ],
    ),
  );
}

Widget editCounterPage(
  BuildContext ctx,
  StateRoutingContext stateCtx,
  CounterData data,
) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(
        'Counter: ${data.counter}',
        style: const TextStyle(fontSize: 24),
      ),
      button('Increment', () => stateCtx.currentState.post(Messages.increment)),
      button('Decrement', () => stateCtx.currentState.post(Messages.decrement)),
      button('Done', () => stateCtx.currentState.post(Messages.endEdit)),
    ],
  );
}
