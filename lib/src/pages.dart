import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';

/// Describes the reason a page is being built.
///
/// If necessary, the [TreeStateRouter.defaultScaffolding] or [TreeStateRouter.defaultPageBuilder]
/// functions can match against the subclasses of [PageBuildFor] in order to customize their results
/// based on the specific reason a page is built.
sealed class PageBuildFor {}

/// Indicates that page content is being built to visualize a state in a state tree.
class BuildForTreeState implements PageBuildFor {
  BuildForTreeState(this.stateKey);

  /// Identifies the tree state for which page content is being built.
  final StateKey stateKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BuildForTreeState &&
          runtimeType == other.runtimeType &&
          stateKey == other.stateKey);

  @override
  int get hashCode {
    var hash = 7;
    hash = 31 * hash + runtimeType.hashCode;
    hash = 31 * hash + stateKey.hashCode;
    return hash;
  }
}

/// Indicates that page content is being built in order to display a navigator loading page.
class BuildForLoading implements PageBuildFor {
  const BuildForLoading();
}

/// Indicates that page content is being built in order to display a navigator error page.
class BuildForError implements PageBuildFor {
  const BuildForError();
}

/// A function that can build a routing page that displays the specified content.
typedef PageBuilder = Page<void> Function(PageBuildFor buildFor, Widget pageContent);

/// Builds a [MaterialPage] that displays the specified content.
PageBuilder materialPageBuilder =
    (buildFor, content) => MaterialPage<void>(key: ValueKey(buildFor), child: content);

/// Builds a [CupertinoPage] that displays the specified content.
PageBuilder cupertinoPageBuilder =
    (buildFor, content) => CupertinoPage<void>(key: ValueKey(buildFor), child: content);
