import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';

/// A route associated with a state in a state tree, which is used to visually display the state in
/// a [Navigator] widget.
///
/// When the state identified by [stateKey] is an active state in a [TreeStateMachine], the
/// [pageBuilder] for this route is used to produce the widget that visualizes the state.
class TreeStateRoute {
  TreeStateRoute(this.stateKey);

  /// The state key identifying the tree state associated with this route.
  final StateKey stateKey;
}
