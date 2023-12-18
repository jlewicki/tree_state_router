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

/// Indicates that page content is being built to visualize a [StateRoute].
class BuildForRoute implements PageBuildFor {
  BuildForRoute(this.stateKey, this.isPopup);

  /// Identifies the state that is being routed.
  final StateKey stateKey;

  /// Indicates if this is a popup route.
  final bool isPopup;

  // Value equality is needed, because this will be used as a key for a Page<void>, and Navigator
  // needs keys for pages to trigger transition animations properly
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BuildForRoute &&
          runtimeType == other.runtimeType &&
          stateKey == other.stateKey &&
          isPopup == other.isPopup);

  @override
  int get hashCode {
    var hash = 7;
    hash = 31 * hash + runtimeType.hashCode;
    hash = 31 * hash + stateKey.hashCode;
    hash = 31 * hash + isPopup.hashCode;
    return hash;
  }
}

/// Indicates that page content is being built in order to display a navigator loading page.
class BuildForLoading implements PageBuildFor {
  const BuildForLoading();
}

/// Indicates that page content is being built in order to display a navigator error page.
class BuildForError implements PageBuildFor {
  const BuildForError(this.error);
  final Object error;
}

/// A function that can build a routing page that displays the specified content.
typedef PageBuilder = Page<void> Function(
  PageBuildFor buildFor,
  Widget pageContent,
);

/// Builds a [MaterialPage] that displays the specified content.
PageBuilder materialPageBuilder = (buildFor, content) =>
    MaterialPage<void>(key: ValueKey(buildFor), child: content);

/// Builds a page that displays the specified content in a Material [DialogRoute].
PageBuilder materialPopupPageBuilder = (buildFor, content) => _PopupPage(
    key: ValueKey(buildFor),
    buildPopupRoute: (context, page) => DialogRoute<void>(
        context: context, builder: (_) => content, settings: page));

/// Builds a [CupertinoPage] that displays the specified content.
PageBuilder cupertinoPageBuilder = (buildFor, content) =>
    CupertinoPage<void>(key: ValueKey(buildFor), child: content);

/// Builds a page that displays the specified content in a [CupertinoDialogRoute].
PageBuilder cupertinoPopupPageBuilder = (buildFor, content) => _PopupPage(
    key: ValueKey(buildFor),
    buildPopupRoute: (context, page) => CupertinoDialogRoute<void>(
          context: context,
          builder: (_) => content,
          settings: page,
        ));

class _PopupPage extends Page<void> {
  const _PopupPage({super.key, required this.buildPopupRoute});
  final PopupRoute<void> Function(BuildContext context, Page<void> page)
      buildPopupRoute;
  @override
  Route<void> createRoute(BuildContext context) {
    return buildPopupRoute(context, this);
  }
}
