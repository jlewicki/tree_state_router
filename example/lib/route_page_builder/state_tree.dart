import 'package:tree_state_machine/delegate_builders.dart';
import 'package:tree_state_machine/tree_state_machine.dart';

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

StateTree hierarchicalDataStateTree() {
  return StateTree(
    InitialChild(States.parent),
    childStates: [
      DataState.composite(
        States.dataParent,
        InitialData(() => ParentData('Parent-1')),
        InitialChild(States.child),
        onMessage: (ctx) {
          if (ctx.message case UpdateParentData(newValue: var nv)) {
            ctx.data(States.dataParent).update((current) => ParentData(nv));
            return ctx.stay();
          }
          return ctx.unhandled();
        },
        childStates: [
          State(
            States.child,
            onMessage: (ctx) => switch (ctx.message) {
              GoToDataChild() => ctx.goTo(States.dataChild),
              _ => ctx.unhandled(),
            },
          )
        ],
      ),
      State.composite(
        States.parent,
        InitialChild(States.dataChild),
        childStates: [
          DataState(
            States.dataChild,
            InitialData(() => ChildData("Child-1")),
            onMessage: (ctx) {
              if (ctx.message case UpdateChildData(newValue: var nv)) {
                ctx.data(States.dataChild).update((current) => ChildData(nv));
                return ctx.stay();
              } else if (ctx.message is GoToChild) {
                return ctx.goTo(States.child);
              }
              return ctx.unhandled();
            },
          )
        ],
      ),
    ],
  );
}
