import 'package:flutter/material.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'package:tree_state_router_examples/helpers/helpers.dart';
import 'state_tree.dart';

Widget rootPage(
  BuildContext buildContext,
  StateRoutingContext stateContext,
  Widget nestedRouter,
) {
  return Scaffold(
    body: Container(
      color: Colors.grey,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: const Text('Root'),
          ),
          Expanded(child: nestedRouter),
        ],
      ),
    ),
  );
}

Widget parent1Page(
  BuildContext buildContext,
  StateRoutingContext stateContext,
  Widget nestedRouter,
) {
  return IntrinsicHeight(
    child: Center(
      child: Container(
        color: Colors.green.shade200,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              child: const Text('Parent 1'),
            ),
            Expanded(child: nestedRouter),
          ],
        ),
      ),
    ),
  );
}

Widget parent2Page(
  BuildContext buildContext,
  StateRoutingContext stateContext,
  Widget nestedRouter,
) {
  return Container(
    padding: const EdgeInsets.all(16),
    color: Colors.blue,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          child: const Text('Parent 2'),
        ),
        Expanded(child: nestedRouter),
      ],
    ),
  );
}

Widget child1Page(
  BuildContext buildContext,
  StateRoutingContext stateContext,
  ChildData data,
) {
  return Container(
    color: Colors.green.shade400,
    child: Align(
      alignment: Alignment.topCenter,
      child: Wrap(
        direction: Axis.vertical,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            child: Text('Child 1 - ID: ${data.id} Value: ${data.value}'),
          ),
          button(
            'Increment',
            () => stateContext.currentState.post(Messages.increment),
          ),
          button(
            'Decrement',
            () => stateContext.currentState.post(Messages.decrement),
          ),
          ElevatedButton(
            onPressed: () =>
                stateContext.currentState.post(Messages.goToParent2),
            child: const Text('Go To Parent 2'),
          ),
          ElevatedButton(
            onPressed: () =>
                stateContext.currentState.post(Messages.goToChild2),
            child: const Text('Go To Child 2'),
          )
        ],
      ),
    ),
  );
}

Widget child2Page(
  BuildContext buildContext,
  StateRoutingContext stateContext,
) {
  return Container(
    color: Colors.green.shade400,
    child: Align(
      alignment: Alignment.topCenter,
      child: Wrap(
        direction: Axis.vertical,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            child: const Text('Child 2'),
          ),
          ElevatedButton(
            onPressed: () =>
                stateContext.currentState.post(Messages.goToChild1),
            child: const Text('Go To Child 1'),
          )
        ],
      ),
    ),
  );
}

Widget child3Page(
  BuildContext buildContext,
  StateRoutingContext stateContext,
) {
  return Container(
    color: Colors.blue.shade400,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          child: const Text('Child 3'),
        ),
        ElevatedButton(
          onPressed: () => stateContext.currentState.post(Messages.goToParent1),
          child: const Text('Go To Parent 1'),
        )
      ],
    ),
  );
}
