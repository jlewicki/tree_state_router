import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_machine/declarative_builders.dart';

class States {
  static const step1 = StateKey('step1');
  static const step2 = StateKey('step2');
  static const step3 = StateKey('step3');
}

enum Messages {
  next,
}

DeclarativeStateTreeBuilder threeStepsStateMachine() {
  var b = DeclarativeStateTreeBuilder(initialChild: States.step1);

  b.state(
    States.step1,
    (b) {
      b.onMessageValue(Messages.next, (b) => b.goTo(States.step2));
    },
  );

  b.state(
    States.step2,
    (b) {
      b.onMessageValue(Messages.next, (b) => b.goTo(States.step3));
    },
  );

  b.finalState(
    States.step3,
    emptyFinalState,
  );

  return b;
}
