import 'package:flutter/material.dart';
import 'package:tree_state_router/tree_state_router.dart';
import '../helpers/helpers.dart';
import 'state_tree.dart';
import 'nested_state_tree.dart' as nested;

Widget nestedMachineReadyPage(
  BuildContext ctx,
  StateRoutingContext stateCtx,
) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        button(
          'Start',
          () => stateCtx.currentState.post(Messages.startNestedMachine),
        ),
      ],
    ),
  );
}

Widget nestedMachineDonePage(
  BuildContext ctx,
  StateRoutingContext stateCtx,
) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        button(
          'Reset',
          () => stateCtx.currentState.post(Messages.reset),
        ),
      ],
    ),
  );
}

Widget nestedMachineStep1(
  BuildContext ctx,
  StateRoutingContext stateCtx,
) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Text('Step 1'),
        button(
          'Next',
          () => stateCtx.currentState.post(nested.Messages.next),
        ),
      ],
    ),
  );
}

Widget nestedMachineStep2(
  BuildContext ctx,
  StateRoutingContext stateCtx,
) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Text('Step 2'),
        button(
          'Next',
          () => stateCtx.currentState.post(nested.Messages.next),
        ),
      ],
    ),
  );
}

Widget nestedMachineStep3(
  BuildContext ctx,
  StateRoutingContext stateCtx,
) {
  return const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text('Step 3'),
      ],
    ),
  );
}
