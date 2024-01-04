import 'package:tree_state_machine/delegate_builders.dart';
import 'package:tree_state_machine/tree_state_machine.dart';

//
// State keys
//
class States {
  static const root = StateKey('root');
  static const parent1 = StateKey('parent1');
  static const child1 = DataStateKey<ChildData>('dataChild1');
  static const child2 = StateKey('child2');
  static const parent2 = StateKey('parent2');
  static const child3 = StateKey('child3');
}

class ChildData {
  ChildData(this.value);
  final String value;
}

enum Messages {
  goToParent1,
  goToParent2,
  goToChild1,
  goToChild2,
}

StateTree routePathsStateTree() {
  return StateTree.root(
    States.root,
    InitialChild(States.parent1),
    childStates: [
      State.composite(
        States.parent1,
        InitialChild(States.child1),
        childStates: [
          State(
            States.child1,
            onMessage: (ctx) => switch (ctx.message) {
              Messages.goToChild2 => ctx.goTo(States.child2),
              Messages.goToParent2 => ctx.goTo(States.parent2),
              _ => ctx.unhandled(),
            },
          ),
          State(
            States.child2,
            onMessage: (ctx) => switch (ctx.message) {
              Messages.goToChild1 => ctx.goTo(States.child1),
              _ => ctx.unhandled(),
            },
          )
        ],
      ),
      State.composite(
        States.parent2,
        InitialChild(States.child3),
        childStates: [
          State(
            States.child3,
            onMessage: (ctx) => ctx.message == Messages.goToParent1
                ? ctx.goTo(States.parent1)
                : ctx.unhandled(),
          ),
        ],
      ),
    ],
  );
}
