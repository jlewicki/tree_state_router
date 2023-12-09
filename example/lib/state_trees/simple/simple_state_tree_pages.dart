import 'package:flutter/material.dart';
import 'package:tree_state_router/tree_state_router.dart';

import 'simple_state_tree.dart';

Widget enterTextPage(
  BuildContext ctx,
  TreeStateRoutingContext stateCtx,
) {
  var currentText = '';

  Widget postMessageButton(String text, Object message) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: () => stateCtx.currentState.post(message),
        child: Text(text),
      ),
    );
  }

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        StatefulBuilder(
          builder: (context, setState) => Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: TextField(
              onChanged: (val) => currentText = val,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter some text',
              ),
            ),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          postMessageButton('To Uppercase', ToUppercase(currentText)),
          postMessageButton('To Lowercase', ToLowercase(currentText)),
        ]),
      ],
    ),
  );
}
