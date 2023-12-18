import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_machine/declarative_builders.dart';

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

DeclarativeStateTreeBuilder readAncestorDataStateTree() {
  var b = DeclarativeStateTreeBuilder.withDataRoot<RootData>(
    States.root,
    InitialData(() => RootData('RootValue')),
    emptyState,
    InitialChild(States.parent),
    logName: 'hierarchicalData',
    label: 'Hierarchical Data State Tree',
  );

  b.dataState<ParentData>(
    States.parent,
    InitialData(() => ParentData("ParentValue")),
    emptyState,
    initialChild: InitialChild(States.child),
    parent: States.root,
  );

  b.dataState<ChildData>(
    States.dataChild,
    InitialData(() => ChildData("ChildValue")),
    (b) {
      b.onMessageValue(Messages.goToChild, (b) => b.goTo(States.child));
    },
    parent: States.parent,
  );

  b.state(
    States.child,
    (b) {
      b.onMessageValue(Messages.goToDataChild, (b) => b.goTo(States.dataChild));
    },
    parent: States.parent,
  );

  return b;
}
