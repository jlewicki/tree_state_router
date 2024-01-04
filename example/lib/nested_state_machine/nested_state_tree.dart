import 'package:tree_state_machine/delegate_builders.dart';
import 'package:tree_state_machine/tree_state_machine.dart';

class States {
  static const step1 = StateKey('step1');
  static const step2 = StateKey('step2');
  static const step3 = StateKey('step3');
}

enum Messages {
  next,
}

StateTree threeStepsStateMachine() {
  return StateTree(
    InitialChild(States.step1),
    childStates: [
      State(
        States.step1,
        onMessage: (ctx) => ctx.message == Messages.next
            ? ctx.goTo(States.step2)
            : ctx.unhandled(),
      ),
      State(
        States.step2,
        onMessage: (ctx) => ctx.message == Messages.next
            ? ctx.goTo(States.step3)
            : ctx.unhandled(),
      ),
    ],
    finalStates: [FinalState(States.step3)],
  );
}
