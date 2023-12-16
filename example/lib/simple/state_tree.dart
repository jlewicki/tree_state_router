import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_machine/declarative_builders.dart';

//
// State keys
//
class States {
  static const enterText = StateKey('enterText');
  static const showUppercase = DataStateKey<String>('showUppercase');
  static const showLowercase = DataStateKey<String>('showLowercase');
  static const finished = StateKey('finished');
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
DeclarativeStateTreeBuilder simpleStateTree() {
  var b = DeclarativeStateTreeBuilder(
    initialChild: States.enterText,
    logName: 'simple',
    label: 'Simple State Tree',
  );

  b.state(States.enterText, (b) {
    b.onMessage<ToUppercase>((b) =>
        b.goTo(States.showUppercase, payload: (ctx) => ctx.message.text));
    b.onMessage<ToLowercase>((b) =>
        b.goTo(States.showLowercase, payload: (ctx) => ctx.message.text));
  });

  b.dataState<String>(
    States.showUppercase,
    InitialData.run((ctx) => (ctx.payload as String).toUpperCase()),
    (b) {
      b.onMessageValue(Messages.finish, (b) => b.goTo(States.finished));
    },
  );

  b.dataState<String>(
    States.showLowercase,
    InitialData.run((ctx) => (ctx.payload as String).toLowerCase()),
    (b) {
      b.onMessageValue(Messages.finish, (b) => b.goTo(States.finished));
    },
  );

  b.finalState(States.finished, emptyFinalState);

  return b;
}
