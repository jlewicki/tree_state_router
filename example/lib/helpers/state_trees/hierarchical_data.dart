import 'package:tree_state_machine/delegate_builders.dart';
import 'package:tree_state_machine/tree_state_machine.dart';

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

StateTree hierarchicalDataStateTree() {
  return StateTree.dataRoot<ParentData>(
    States.parent,
    InitialData(() => ParentData('This is the parent value')),
    InitialChild(States.child1),
    childStates: [
      DataState<Child1Data>(
        States.child1,
        InitialData(() => Child1Data("This is the value from child 1")),
        onMessage: (ctx) {
          if (ctx.message case UpdateChildData(newValue: var v)) {
            ctx.data(States.child1).update((_) => Child1Data(v));
            return ctx.stay();
          } else if (ctx.message is GoToChild2) {
            return ctx.goTo(States.child2);
          }
          return ctx.unhandled();
        },
      ),
      DataState<Child2Data>(
        States.child2,
        InitialData(() => Child2Data("This is the value from child 2")),
        onMessage: (ctx) {
          if (ctx.message case UpdateChildData(newValue: var v)) {
            ctx.data(States.child2).update((_) => Child2Data(v));
            return ctx.stay();
          } else if (ctx.message is GoToChild1) {
            return ctx.goTo(States.child1);
          }
          return ctx.unhandled();
        },
      ),
    ],
  );
}
