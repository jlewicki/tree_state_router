import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_machine/declarative_builders.dart';

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

DeclarativeStateTreeBuilder routePathsStateTree() {
  var b = DeclarativeStateTreeBuilder.withRoot(
    States.root,
    InitialChild(States.parent1),
    emptyState,
    logName: 'routePaths',
    label: 'Route Paths State Tree',
  );

  b.state(
    States.parent1,
    emptyState,
    parent: States.root,
    initialChild: InitialChild(States.child1),
  );

  b.dataState(
    States.child1,
    InitialData(() => ChildData("Hi")),
    (b) {
      b.onMessageValue(Messages.goToParent2, (b) => b.goTo(States.parent2));
      b.onMessageValue(Messages.goToChild2, (b) => b.goTo(States.child2));
    },
    parent: States.parent1,
  );

  b.state(
    States.child2,
    (b) {
      b.onMessageValue(Messages.goToChild1, (b) => b.goTo(States.child1));
    },
    parent: States.parent1,
  );

  b.state(
    States.parent2,
    emptyState,
    parent: States.root,
    initialChild: InitialChild(States.child3),
  );

  b.state(
    States.child3,
    (b) {
      b.onMessageValue(Messages.goToParent1, (b) => b.goTo(States.parent1));
    },
    parent: States.parent2,
  );

  return b;
}
