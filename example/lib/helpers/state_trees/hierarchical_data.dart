import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_machine/declarative_builders.dart';

//
// State keys
//
class States {
  static const parent = DataStateKey<ParentData>('parent');
  static const child1 = DataStateKey<Child1Data>('child1');
  static const child2 = DataStateKey<Child2Data>('child2');
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

class GoToChild2 {}

class GoToChild1 {}

//
// Models
//
class ParentData {
  ParentData(this.value);
  final String value;
}

class Child1Data {
  Child1Data(this.value);
  final String value;
}

class Child2Data {
  Child2Data(this.value);
  final String value;
}

DeclarativeStateTreeBuilder hierarchicalDataStateTree() {
  var b = DeclarativeStateTreeBuilder.withDataRoot<ParentData>(
    States.parent,
    InitialData(() => ParentData('This is the parent value')),
    (b) {
      b.onMessage<UpdateParentData>(
        (b) => b.stay(
            action:
                b.act.updateOwnData((ctx) => ParentData(ctx.message.newValue))),
      );
    },
    InitialChild(States.child1),
    logName: 'hierarchicalData',
    label: 'Hierarchical Data State Tree',
  );

  b.dataState<Child1Data>(
    States.child1,
    InitialData(() => Child1Data("This is the value from child 1")),
    (b) {
      b.onMessage<UpdateChildData>(
        (b) => b.stay(
            action:
                b.act.updateOwnData((ctx) => Child1Data(ctx.message.newValue))),
      );
      b.onMessage<GoToChild2>((b) => b.goTo(States.child2));
    },
    parent: States.parent,
  );

  b.dataState<Child2Data>(
    States.child2,
    InitialData(() => Child2Data("This is the value from child 2")),
    (b) {
      b.onMessage<UpdateChildData>(
        (b) => b.stay(
            action:
                b.act.updateOwnData((ctx) => Child2Data(ctx.message.newValue))),
      );
      b.onMessage<GoToChild1>((b) => b.goTo(States.child1));
    },
    parent: States.parent,
  );

  return b;
}
