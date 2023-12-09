import 'package:flutter/material.dart';
import 'package:tree_state_router/tree_state_router.dart';

import 'simple_state_tree.dart';

Widget enterTextPage(
  BuildContext ctx,
  TreeStateRoutingContext stateCtx,
) {
  var currentText = '';

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        StatefulBuilder(
          builder: (context, setState) => Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: TextField(
              onChanged: (val) => setState(() => currentText = val),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter some text',
              ),
            ),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _button('To Uppercase', () => stateCtx.currentState.post(ToUppercase(currentText))),
          _button('To Lowercase', () => stateCtx.currentState.post(ToLowercase(currentText))),
        ]),
      ],
    ),
  );
}

Widget toUppercasePage(
  BuildContext ctx,
  TreeStateRoutingContext stateCtx,
  String text,
) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        'Uppercase text: $text',
        style: const TextStyle(fontSize: 24),
      ),
      _button('Done', () => stateCtx.currentState.post(Messages.finish)),
    ],
  );
}

Widget toLowercasePage(
  BuildContext ctx,
  TreeStateRoutingContext stateCtx,
  String text,
) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        'Lowercase text: $text',
        style: const TextStyle(fontSize: 24),
      ),
      _button('Done', () => stateCtx.currentState.post(Messages.finish)),
    ],
  );
}

Widget finishedPage(BuildContext ctx, TreeStateRoutingContext stateCtx) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text('The state machine has finished'),
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
