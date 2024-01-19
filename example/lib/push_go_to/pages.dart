import 'package:flutter/material.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'package:tree_state_router_examples/helpers/helpers.dart';
import 'state_tree.dart';

Widget statePage(
  BuildContext ctx,
  StateRoutingContext stateCtx,
  String stateName,
) {
  return Scaffold(
    appBar: AppBar(
      title: Text(stateName),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(stateName),
          button('Next', () => stateCtx.currentState.post(Messages.go)),
        ],
      ),
    ),
  );
}
