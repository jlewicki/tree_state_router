import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_machine/tree_builders.dart';

//
// State keys
//
class SimpleStates {
  static const enterText = StateKey('simple_enterText');
  static const showUppercase = DataStateKey<String>('simple_showUppercase');
  static const showLowercase = DataStateKey<String>('simple_showLowercase');
  static const finished = StateKey('simple_finished');
}

typedef _S = SimpleStates;

//
// Messages
//
enum Messages { finish }

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
class SimpleStateTree {
  StateTreeBuilder treeBuilder() {
    var b = StateTreeBuilder(initialChild: _S.enterText, logName: 'simple');

    b.state(_S.enterText, (b) {
      b.onMessage<ToUppercase>((b) => b.goTo(_S.showUppercase, payload: (ctx) => ctx.message.text));
      b.onMessage<ToLowercase>((b) => b.goTo(_S.showLowercase, payload: (ctx) => ctx.message.text));
    });

    b.dataState<String>(
      _S.showUppercase,
      InitialData.run((ctx) => (ctx.payload as String).toUpperCase()),
      (b) {
        b.onMessageValue(Messages.finish, (b) => b.goTo(SimpleStates.finished));
      },
    );

    b.dataState<String>(
      _S.showLowercase,
      InitialData.run((ctx) => (ctx.payload as String).toLowerCase()),
      (b) {
        b.onMessageValue(Messages.finish, (b) => b.goTo(SimpleStates.finished));
      },
    );

    b.finalState(_S.finished, emptyFinalState);

    return b;
  }
}
