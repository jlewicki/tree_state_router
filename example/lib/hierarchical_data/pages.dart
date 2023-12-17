import 'package:flutter/material.dart';
import 'package:tree_state_router/tree_state_router.dart';
import '../../helpers/helpers.dart';
import '../../helpers/state_trees/hierarchical_data.dart';

Widget child1Page(
  BuildContext ctx,
  StateRoutingContext stateCtx,
  Child1Data data,
  ParentData parentData,
) {
  var textForParent = "";
  var textForChild1 = "";

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8.0),
          child: Text('Parent data: ${parentData.value}'),
        ),
        Container(
          padding: const EdgeInsets.all(8.0),
          child: Text('Child1 data: ${data.value}'),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              editText(parentData.value, 'Enter value for Parent',
                  (val) => textForParent = val),
              button(
                'Update Parent data',
                () =>
                    stateCtx.currentState.post(UpdateParentData(textForParent)),
              )
            ],
          ),
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
                () =>
                    stateCtx.currentState.post(UpdateChildData(textForChild1)),
              )
            ],
          ),
        ),
        button(
          'Go to Child2',
          () => stateCtx.currentState.post(GoToChild2()),
        ),
      ],
    ),
  );
}

Widget child2Page(
  BuildContext ctx,
  StateRoutingContext stateCtx,
  Child2Data data,
  ParentData parentData,
) {
  var textForParent = "";
  var textForChild2 = "";

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8.0),
          child: Text('Parent data: ${parentData.value}'),
        ),
        Container(
          padding: const EdgeInsets.all(8.0),
          child: Text('Child 2 data: ${data.value}'),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              editText(parentData.value, 'Enter value for Parent',
                  (val) => textForParent = val),
              button(
                'Update Parent data',
                () =>
                    stateCtx.currentState.post(UpdateParentData(textForParent)),
              )
            ],
          ),
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
                () =>
                    stateCtx.currentState.post(UpdateChildData(textForChild2)),
              )
            ],
          ),
        ),
        button(
          'Go to Child1',
          () => stateCtx.currentState.post(GoToChild1()),
        ),
      ],
    ),
  );
}
