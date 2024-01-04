import 'package:tree_state_machine/delegate_builders.dart';
import 'package:tree_state_machine/tree_state_machine.dart';

class CounterData {
  CounterData(this.counter);
  final int counter;
}

class States {
  static const counting = DataStateKey<CounterData>("counting");
  static const view = StateKey('view');
  static const edit = StateKey('edit');
}

enum Messages { increment, decrement, edit, endEdit }

StateTree countingStateTree() {
  return StateTree.dataRoot(
    States.counting,
    InitialData(() => CounterData(0)),
    InitialChild(States.view),
    childStates: [
      State(
        States.view,
        onMessage: (ctx) => ctx.message == Messages.edit
            ? ctx.goTo(States.edit)
            : ctx.unhandled(),
      ),
      State(
        States.edit,
        onMessage: (ctx) {
          if (ctx.message == Messages.increment) {
            ctx
                .data(States.counting)
                .update((current) => CounterData(current.counter + 1));
            return ctx.stay();
          } else if (ctx.message == Messages.increment) {
            ctx
                .data(States.counting)
                .update((current) => CounterData(current.counter - 1));
            return ctx.stay();
          } else if (ctx.message == Messages.endEdit) {
            return ctx.goTo(States.view);
          }
          return ctx.unhandled();
        },
      ),
    ],
  );
}
