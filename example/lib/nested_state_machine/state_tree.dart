import 'package:tree_state_machine/build.dart';
import 'package:tree_state_machine/delegate_builders.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'nested_state_tree.dart' as nested;

class States {
  static const root = StateKey('root');
  static const nestedMachineReady = StateKey('nestedMachineReady');
  static const nestedMachineRunning = MachineStateKey('nestedMachineRunning');
  static const nestedMachineDone = StateKey('nestedMachineRunning');
}

enum Messages {
  startNestedMachine,
  reset,
}

StateTree nestedStateMachineStateTree() {
  return StateTree.root(
    States.root,
    InitialChild(States.nestedMachineReady),
    childStates: [
      State(
        States.nestedMachineReady,
        onMessage: (ctx) => ctx.message == Messages.startNestedMachine
            ? ctx.goTo(States.nestedMachineRunning)
            : ctx.unhandled(),
      ),
      MachineState(
        States.nestedMachineRunning,
        InitialMachine.fromStateTree(
          (transCtx) => nested.threeStepsStateMachine(),
        ),
        onMachineDone: (ctx, _) => ctx.goTo(States.nestedMachineDone),
      ),
      State(
        States.nestedMachineDone,
        onMessage: (ctx) => ctx.message == Messages.reset
            ? ctx.goTo(States.nestedMachineReady)
            : ctx.unhandled(),
      ),
    ],
  );
}
