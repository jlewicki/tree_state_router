import 'package:flutter/material.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'state_tree.dart';

Widget child1Page(BuildContext ctx, TreeStateRoutingContext stateCtx, Child1Data data) {
  var currentText = "";

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(padding: const EdgeInsets.all(8.0), child: Text('Child1 data: ${data.value}')),
        StatefulBuilder(
          builder: (context, setState) => Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: TextField(
              onChanged: (val) => setState(() => currentText = val),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter value for Child1',
              ),
            ),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _button(
            'Update Child1 data',
            () => stateCtx.currentState.post(UpdateChildData(currentText)),
          ),
          _button(
            'Go to Child2',
            () => stateCtx.currentState.post(GoToChild2()),
          )
        ]),
      ],
    ),
  );
}

Widget child2Page(BuildContext ctx, TreeStateRoutingContext stateCtx, Child2Data data) {
  var currentText = "";

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(padding: const EdgeInsets.all(8.0), child: Text('Child 2 data: ${data.value}')),
        StatefulBuilder(
          builder: (context, setState) => Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: TextField(
              onChanged: (val) => setState(() => currentText = val),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter value for Child2',
              ),
            ),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _button(
            'Update Child2 data',
            () => stateCtx.currentState.post(UpdateChildData(currentText)),
          ),
          _button(
            'Go to Child1',
            () => stateCtx.currentState.post(GoToChild1()),
          )
        ]),
      ],
    ),
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
