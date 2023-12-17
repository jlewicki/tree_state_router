import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_machine/declarative_builders.dart';

//
// State keys
//
class States {
  static const dataParent = DataStateKey<ParentData>('dataParent');
  static const parent = StateKey('parent');
  static const dataChild = DataStateKey<ChildData>('dataChild');
  static const child = StateKey('child');
}

//
// Models
//
class ParentData {
  ParentData(this.value);
  final String value;
}

class ChildData {
  ChildData(this.value);
  final String value;
}

//
// Messages
//
class UpdateParentData {
  UpdateParentData(this.newValue);
  final String newValue;
}

class UpdateChildData {
  UpdateChildData(this.newValue);
  final String newValue;
}

class GoToDataChild {}

class GoToChild {}

DeclarativeStateTreeBuilder hierarchicalDataStateTree() {
  var b = DeclarativeStateTreeBuilder(
    initialChild: States.parent,
    logName: 'hierarchicalData',
    label: 'Hierarchical Data State Tree',
  );

  b.dataState<ParentData>(
    States.dataParent,
    InitialData(() => ParentData('Parent-1')),
    (b) {
      b.onMessage<UpdateParentData>(
        (b) => b.stay(
            action:
                b.act.updateOwnData((ctx) => ParentData(ctx.message.newValue))),
      );
    },
    initialChild: InitialChild(States.child),
  );

  b.state(
    States.parent,
    emptyState,
    initialChild: InitialChild(States.dataChild),
  );

  b.dataState<ChildData>(
    States.dataChild,
    InitialData(() => ChildData("Child-1")),
    (b) {
      b.onMessage<UpdateChildData>(
        (b) => b.stay(
            action:
                b.act.updateOwnData((ctx) => ChildData(ctx.message.newValue))),
      );
      b.onMessage<GoToChild>((b) => b.goTo(States.child));
    },
    parent: States.parent,
  );

  b.state(
    States.child,
    (b) {
      b.onMessage<GoToDataChild>((b) => b.goTo(States.dataChild));
    },
    parent: States.dataParent,
  );

  return b;
}
