import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';

sealed class PageBuildFor {}

class BuildForTreeState implements PageBuildFor {
  BuildForTreeState(this.stateKey);
  final StateKey stateKey;
}

class BuildForLoading implements PageBuildFor {}

class BuildForError implements PageBuildFor {}

typedef PageBuilder = Page<void> Function(PageBuildFor buildFor, Widget pageContent);

// Page<void> treeStatePageBuilder(
//   StateKey stateKey,
//   TreeStateWidgetBuilder builder,
//   PageBuilder platformPageBuilder,
// ) {
//   var pageContent = TreeStateView(
//     key: ValueKey(stateKey),
//     stateKey: stateKey,
//     builder: builder,
//   );
//   return platformPageBuilder.call(ValueKey(stateKey), pageContent);
// }
