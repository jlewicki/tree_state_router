import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_machine/delegate_builders.dart';

//
// State keys
//
class States {
  static const root = DataStateKey<RootData>('root');
  static const parent = DataStateKey<ParentData>('parent');
  static const child = DataStateKey<ParentData>('child');
  static const dataChild = DataStateKey<ChildData>('dataChild');
}

enum Messages { goToDataChild, goToChild }

//
// Models
//
class RootData {
  RootData(this.value);
  final String value;
}

class ParentData {
  ParentData(this.value);
  final String value;
}

class ChildData {
  ChildData(this.value);
  final String value;
}

StateTree readAncestorDataStateTree() {
  return StateTree.dataRoot<RootData>(
    States.root,
    InitialData(() => RootData('RootValue')),
    InitialChild(States.parent),
    childStates: [
      DataState.composite(
        States.parent,
        InitialData(() => ParentData("ParentValue")),
        InitialChild(States.child),
        childStates: [
          DataState(
            States.dataChild,
            InitialData(() => ChildData("ChildValue")),
            onMessage: (ctx) => switch (ctx.message) {
              Messages.goToChild => ctx.goTo(States.child),
              _ => ctx.unhandled(),
            },
          ),
          State(
            States.child,
            onMessage: (ctx) => switch (ctx.message) {
              Messages.goToDataChild => ctx.goTo(States.dataChild),
              _ => ctx.unhandled(),
            },
          ),
        ],
      ),
    ],
  );
}
