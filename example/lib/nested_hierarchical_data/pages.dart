import 'package:flutter/material.dart';
import 'package:tree_state_router/tree_state_router.dart';
import '../../helpers/helpers.dart';
import '../../helpers/state_trees/hierarchical_data.dart';

Widget parentPage(
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
        child: Text('Parent data: ${parentData.value}'),
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
      IntrinsicHeight(child: nestedRouter),
      // IntrinsicHeight(
      //   child: DescendantStatesRouter(
      //     anchorKey: States.parent,
      //     enableTransitions: false,
      //     routes: [
      //       DataStateRoute(States.child1, routeBuilder: child1Page),
      //       DataStateRoute(States.child2, routeBuilder: child2Page),
      //     ],
      //   ),
      // )
    ],
  );
}

Widget child1Page(
    BuildContext ctx, StateRoutingContext stateCtx, Child1Data data) {
  var textForChild1 = "";

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(
        padding: const EdgeInsets.all(8.0),
        child: Text('Child1 data: ${data.value}'),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            editText(data.value, 'Enter value for Child1',
                (val) => textForChild1 = val),
            button(
              'Update Child1 data',
              () => stateCtx.currentState.post(UpdateChildData(textForChild1)),
            )
          ],
        ),
      ),
      button(
        'Go to Child2',
        () => stateCtx.currentState.post(GoToChild2()),
      ),
    ],
  );
}

Widget child2Page(
    BuildContext ctx, StateRoutingContext stateCtx, Child2Data data) {
  var textForChild2 = "";

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
            editText(data.value, 'Enter value for Child2',
                (val) => textForChild2 = val),
            button(
              'Update Child2 data',
              () => stateCtx.currentState.post(UpdateChildData(textForChild2)),
            )
          ],
        ),
      ),
      button(
        'Go to Child1',
        () => stateCtx.currentState.post(GoToChild1()),
      ),
    ],
  );
}
