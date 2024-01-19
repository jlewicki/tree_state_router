// Define a simple state tree with 2 states
import 'package:tree_state_machine/delegate_builders.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';

class States {
  static const state1 = StateKey('state1');
  static const state2 = StateKey('state2');
  static const state3 = StateKey('state3');
  static const state4 = StateKey('state4');
}

enum Messages { go, goBack }

StateTree pushGoToStateTree() {
  return StateTree(
    InitialChild(States.state1),
    childStates: [
      State(
        States.state1,
        onMessage: (ctx) => switch (ctx.message) {
          Messages.go =>
            ctx.pushGoTo(States.state2, popMessage: Messages.goBack),
          _ => ctx.unhandled()
        },
      ),
      State(
        States.state2,
        onMessage: (ctx) => switch (ctx.message) {
          Messages.go =>
            ctx.pushGoTo(States.state3, popMessage: Messages.goBack),
          Messages.goBack => ctx.goTo(States.state1),
          _ => ctx.unhandled()
        },
      ),
      State(
        States.state3,
        onMessage: (ctx) => switch (ctx.message) {
          Messages.go =>
            ctx.pushGoTo(States.state4, popMessage: Messages.goBack),
          Messages.goBack => ctx.goTo(States.state2),
          _ => ctx.unhandled()
        },
      ),
      State(
        States.state4,
        onEnter: (ctx) => ctx.redirectTo(States.state1),
      ),
    ],
  );
}
