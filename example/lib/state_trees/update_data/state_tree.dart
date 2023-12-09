import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_machine/tree_builders.dart';

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
StateTreeBuilder countingStateTree() {
  var b = StateTreeBuilder(
    initialChild: States.counting,
    logName: 'simple',
    label: 'Simple State Tree',
  );

  b.dataState(States.counting, InitialData(() => CounterData(0)), (b) {
    b.onMessageValue(Messages.increment,
        (b) => b.stay(action: b.act.updateOwnData((ctx) => CounterData(ctx.data.counter + 1))));
    b.onMessageValue(Messages.decrement,
        (b) => b.stay(action: b.act.updateOwnData((ctx) => CounterData(ctx.data.counter - 1))));
  });

  return b;
}
