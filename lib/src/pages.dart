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

/// {@template TransitionsBuilder}
/// A function that can wraps the [child] with one or more transition widgets
/// which define how a [Route] arrives on and leaves the screen.
///
/// See [ModalRoute.buildTransitions] for further details on this function is
/// used.
/// {@endtemplate
typedef TransitionsBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
);

/// A [Page] that allows for customization of route transition animations.
///
/// In order to customize the transitions, this class can be subclassed and
/// the [buildTransitions] method overridden, or alternatively a
/// [transitionsBuilder] can be provided when calling
/// [TransitionsBuilderPage.new]

class TransitionsBuilderPage<T> extends Page<T> {
  const TransitionsBuilderPage({
    required this.child,
    required super.key,
    this.transitionsBuilder,
    this.maintainState = true,
    this.transitionDuration = const Duration(milliseconds: 300),
  });

  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  /// {@macro TransitionsBuilder}
  final TransitionsBuilder? transitionsBuilder;

  final bool maintainState;

  final Duration transitionDuration;

  @override
  Route<T> createRoute(BuildContext context) {
    return TransitionsBuilderPageRoute<T>(this);
  }

  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return transitionsBuilder != null
        ? transitionsBuilder!(context, animation, secondaryAnimation, child)
        : child;
  }
}

class TransitionsBuilderPageRoute<T> extends PageRoute<T> {
  TransitionsBuilderPageRoute(this._page) : super(settings: _page);

  final TransitionsBuilderPage<T> _page;

  @override
  // not sure about this?
  Color? get barrierColor => null;

  @override
  // not sure about this?
  String? get barrierLabel => null;

  @override
  bool get maintainState => _page.maintainState;

  @override
  Duration get transitionDuration => _page.transitionDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: _page.child,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _page.buildTransitions(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
