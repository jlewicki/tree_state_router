import 'package:tree_state_machine/build.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_machine/declarative_builders.dart';
import 'nested_state_tree.dart' as nested;

class States {
  static const root = StateKey('root');
  static const nestedMachineReady = StateKey('nestedMachineReady');
  static const nestedMachineRunning =
      DataStateKey<NestedMachineData>('nestedMachineRunning');
  static const nestedMachineDone = StateKey('nestedMachineRunning');
}

enum Messages {
  startNestedMachine,
  reset,
}

DeclarativeStateTreeBuilder nestedStateMachineStateTree() {
  var b = DeclarativeStateTreeBuilder.withRoot(
    States.root,
    InitialChild(States.nestedMachineReady),
    emptyState,
    logName: 'nestedStateMachine',
    label: 'Nested State Machine',
  );

  b.state(
    States.nestedMachineReady,
    (b) {
      b.onMessageValue(
        Messages.startNestedMachine,
        (b) => b.goTo(States.nestedMachineRunning),
      );
    },
    parent: States.root,
  );

  b.machineState(
    States.nestedMachineRunning,
    InitialMachine.fromTree(
      (_) => StateTreeBuilder(nested.threeStepsStateMachine()),
      label: 'Hierarchical Data State Machine',
    ),
    (b) => b.onMachineDone((b) => b.goTo(States.nestedMachineDone)),
    parent: States.root,
  );

  b.state(
    States.nestedMachineDone,
    (b) {
      b.onMessageValue(
        Messages.reset,
        (b) => b.goTo(States.nestedMachineReady),
      );
    },
    parent: States.root,
  );

  return b;
}
