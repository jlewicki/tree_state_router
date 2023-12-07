import 'package:flutter/material.dart';
import 'package:tree_state_machine/tree_state_machine.dart';

class TreeStatePage extends MaterialPage<void> {
  TreeStatePage._(this.stateKey, this.builder)
      : super(key: ValueKey(stateKey), child: Builder(builder: builder));

  /// The state key identifying the tree state that is displayed by this page.
  final StateKey stateKey;

  /// The builder that creates the widget that displays the tree state.
  final WidgetBuilder builder;
}
