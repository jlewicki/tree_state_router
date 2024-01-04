import 'package:tree_state_machine/delegate_builders.dart';
import 'package:tree_state_machine/tree_state_machine.dart';

//
// State keys
//
class States {
  static const enterText = StateKey('enterText');
  static const showUppercase = DataStateKey<String>('showUppercase');
  static const showLowercase = DataStateKey<String>('showLowercase');
  static const finished = DataStateKey<String>('finished');
}

//
// Messages
//
enum Messages {
  finish,
}

class ToUppercase {
  ToUppercase(this.text);
  final String text;
}

class ToLowercase {
  ToLowercase(this.text);
  final String text;
}

/// A simple flat (non-hierarchial) state tree illustrating simple branching and passing data between
/// states.
StateTree simpleStateTree() {
  return StateTree(
    InitialChild(States.enterText),
    childStates: [
      State(
        States.enterText,
        onMessage: (ctx) => switch (ctx.message) {
          ToUppercase(text: var text) =>
            ctx.goTo(States.showUppercase, payload: text),
          ToLowercase(text: var text) =>
            ctx.goTo(States.showLowercase, payload: text),
          _ => ctx.unhandled()
        },
      ),
      DataState(
        States.showUppercase,
        InitialData.run((ctx) => (ctx.payload as String).toUpperCase()),
        onMessage: (ctx) => ctx.message == Messages.finish
            ? ctx.goTo(States.finished,
                payload: ctx.data(States.showUppercase).value)
            : ctx.unhandled(),
      ),
      DataState(
        States.showLowercase,
        InitialData.run((ctx) => (ctx.payload as String).toLowerCase()),
        onMessage: (ctx) => ctx.message == Messages.finish
            ? ctx.goTo(States.finished,
                payload: ctx.data(States.showLowercase).value)
            : ctx.unhandled(),
      ),
    ],
    finalStates: [
      FinalDataState(
        States.finished,
        InitialData.run((ctx) => ((ctx.payload ?? '') as String)),
      ),
    ],
  );
}
