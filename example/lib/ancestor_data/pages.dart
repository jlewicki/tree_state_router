import 'package:flutter/material.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'package:tree_state_router_examples/helpers/helpers.dart';
import 'state_tree.dart';

Widget childPage(
  BuildContext ctx,
  StateRoutingContext stateCtx,
  ParentData parentData,
  RootData rootData,
) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        'Root Data: ${rootData.value}',
        style: const TextStyle(fontSize: 24),
      ),
      Text(
        'Parent Data: ${parentData.value}',
        style: const TextStyle(fontSize: 24),
      ),
      button('Go to DataChild page',
          () => stateCtx.currentState.post(Messages.goToDataChild)),
    ],
  );
}

Widget dataChildPage(
  BuildContext ctx,
  StateRoutingContext stateCtx,
  ChildData childData,
  ParentData parentData,
  RootData rootData,
) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        'Root Data: ${rootData.value}',
        style: const TextStyle(fontSize: 24),
      ),
      Text(
        'Parent Data: ${parentData.value}',
        style: const TextStyle(fontSize: 24),
      ),
      Text(
        'Child Data: ${childData.value}',
        style: const TextStyle(fontSize: 24),
      ),
      button('Go to Child page',
          () => stateCtx.currentState.post(Messages.goToChild)),
    ],
  );
}
