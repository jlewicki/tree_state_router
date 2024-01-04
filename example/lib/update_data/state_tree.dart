import 'package:tree_state_machine/delegate_builders.dart';
import 'package:tree_state_machine/tree_state_machine.dart';

class CounterData {
  CounterData(this.counter);
  final int counter;
}

class States {
  static const counting = DataStateKey<CounterData>("counting");
}

enum Messages {
  increment,
  decrement,
}

/// A state tree with a single data state that keeps track of a counter.
StateTree countingStateTree() {
  return StateTree(
    InitialChild(States.counting),
    childStates: [
      DataState(
        States.counting,
        InitialData(() => CounterData(0)),
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
          }
          return ctx.unhandled();
        },
      )
    ],
  );
}
