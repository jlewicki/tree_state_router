import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_machine/tree_builders.dart';

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

/// A state tree with states for viewing and editing a counter value stored in a parent state.
StateTreeBuilder countingStateTree() {
  var b = StateTreeBuilder.withDataRoot<CounterData>(
    States.counting,
    InitialData(() => CounterData(0)),
    emptyState,
    InitialChild(States.view),
    logName: 'simple',
    label: 'Simple State Tree',
  );

  b.state(
    States.view,
    (b) {
      b.onMessageValue(Messages.edit, (b) => b.goTo(States.edit));
    },
    parent: States.counting,
  );

  b.state(States.edit, (b) {
    b.onMessageValue(
      Messages.increment,
      (b) => b.stay(
        action: b.act.updateData<CounterData>((ctx, data) => CounterData(data.counter + 1)),
      ),
    );
    b.onMessageValue(
      Messages.decrement,
      (b) => b.stay(
        action: b.act.updateData<CounterData>((ctx, data) => CounterData(data.counter - 1)),
      ),
    );
    b.onMessageValue(Messages.endEdit, (b) => b.goTo(States.view));
  }, parent: States.counting);

  return b;
}
