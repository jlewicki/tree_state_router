import 'package:flutter/material.dart';
import 'package:tree_state_router/tree_state_router.dart';
import '../../helpers/helpers.dart';
import 'state_tree.dart';

Widget dataParentPage(
  BuildContext ctx,
  StateRoutingContext stateCtx,
  Widget nestedRouter,
  ParentData parentData,
) {
  var textForParent = "";

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(
        padding: const EdgeInsets.all(8.0),
        child: Text('This is the data parent state: ${parentData.value}'),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            editText(
              parentData.value,
              'Enter value for Parent',
              (val) => textForParent = val,
            ),
            button(
              'Update Parent data',
              () => stateCtx.currentState.post(UpdateParentData(textForParent)),
            )
          ],
        ),
      ),
      IntrinsicHeight(child: nestedRouter)
    ],
  );
}

Widget parentPage(
  BuildContext ctx,
  StateRoutingContext stateCtx,
  Widget nestedRouter,
) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(
        padding: const EdgeInsets.all(8.0),
        child: const Text('This is the parent state'),
      ),
      IntrinsicHeight(child: nestedRouter)
    ],
  );
}

Widget childPage(BuildContext ctx, StateRoutingContext stateCtx) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(
        padding: const EdgeInsets.all(8.0),
        child: const Text('This is the child state'),
      ),
      button(
        'Go to dataChild',
        () => stateCtx.currentState.post(GoToDataChild()),
      ),
    ],
  );
}

Widget dataChildPage(
  BuildContext ctx,
  StateRoutingContext stateCtx,
  ChildData data,
) {
  var textForChildData = "";

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(
        padding: const EdgeInsets.all(8.0),
        child: Text('Child2 data: ${data.value}'),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            editText(data.value, 'Enter value for ChildData',
                (val) => textForChildData = val),
            button(
              'Update ChildData',
              () =>
                  stateCtx.currentState.post(UpdateChildData(textForChildData)),
            )
          ],
        ),
      ),
      button(
        'Go to Child1',
        () => stateCtx.currentState.post(GoToChild()),
      ),
    ],
  );
}
