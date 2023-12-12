import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/pages.dart';
import 'package:tree_state_router/src/parser.dart';
import 'package:tree_state_router/src/widgets/state_machine_error.dart';
import 'package:tree_state_router/src/widgets/state_machine_events.dart';
import 'package:tree_state_router/tree_state_router.dart';

class TreeStateRouterDelegateConfig {
  TreeStateRouterDelegateConfig(
    this.routes, {
    this.defaultPageBuilder,
    this.defaultScaffolding,
    this.enableTransitions = true,
  });
  final List<TreeStateRoute> routes;
  final DefaultScaffoldingBuilder? defaultScaffolding;
  final DefaultPageBuilder? defaultPageBuilder;
  final bool enableTransitions;
}

abstract class BaseTreeStateRouterDelegate extends RouterDelegate<TreeStateRouteInfo>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  BaseTreeStateRouterDelegate({
    required this.config,
    required Logger logger,
    this.displayStateMachineErrors = false,
  }) : _logger = logger;

  /// Configuration information for this router delegate describing the available routed.
  final TreeStateRouterDelegateConfig config;

  /// If `true`, this router delegate will display an [ErrorWidget] when the
  /// [TreeStateMachine.failedMessages] stream emits an event.
  ///
  /// This is primarily useful for debugging purposes.
  final bool displayStateMachineErrors;

  final Logger _logger;
  late final Map<StateKey, TreeStateRoute> _routeMap = _mapRoutes(_routes);
  List<TreeStateRoute> get _routes => config.routes;
  DefaultScaffoldingBuilder? get _defaultScaffolding => config.defaultScaffolding;
  DefaultPageBuilder? get _defaultPageBuilder => config.defaultPageBuilder;

  // Used to create Page<Object> when routes are unopinionated about which Page type to use.
  PageBuilder? _pageBuilder;

  Page<void> _dialogPageBuilder(PageBuildFor buildFor, Widget pageContent) {
    return _PopupPage(pageContent);
  }

  Widget _buildNavigatorWidget(
    List<Page> pages,
    CurrentState? currentState, {
    required bool provideCurrentState,
    List<TreeStateRoute> popupRoutes = const [],
  }) {
    Widget widget = Navigator(
      key: navigatorKey,
      pages: pages,
      onPopPage: _onPopPage,
      transitionDelegate: config.enableTransitions
          ? const DefaultTransitionDelegate()
          : const _NoTransitionsTransitionDelegate(),
    );

    if (currentState != null) {
      widget = TreeStateMachineEvents(
        onTransition: _onTransition,
        child: displayStateMachineErrors
            ? StateMachineErrorBuilder(
                errorBuilder: _buildErrorWidget,
                child: widget,
              )
            : widget,
      );
    }

    if (provideCurrentState) {
      widget = TreeStateMachineProvider(currentState: currentState!, child: widget);
    }

    return widget;
  }

  Iterable<TreeStateRoute> _findRoutesFor(Iterable<StateKey> keys) {
    return keys
        .map((stateKey) => MapEntry<StateKey, TreeStateRoute?>(stateKey, _routeMap[stateKey]))
        .where((entry) => entry.value != null)
        .map((entry) => entry.value!);
  }

  /// Calculates the stack of routes that should display the current state of the state tree.
  ///
  /// Currently this returns a collection of 0 or 1 pages, but once a history feature is added to
  /// tree_state_machine, this will return a history stack which can be popped by the navigator.
  @protected
  Iterable<Page<void>> _buildActivePages(BuildContext context, CurrentState currentState) {
    /// Return the deepest page that maps to an active state. By deepest, we mean the page that
    /// maps to a state as far as possible from the root state. This gives the current leaf state
    /// priority in determining the page to display, followed by its parent state, etc.
    var activeRoutes = _findRoutesFor(currentState.activeStates.reversed).toList();

    var navigatorRoutes = activeRoutes.take(1);
    if (activeRoutes.isNotEmpty && activeRoutes.first.isPopup) {
      assert(_transition != null);
      navigatorRoutes = _findRoutesFor(_transition!.exitPath).followedBy(navigatorRoutes);
    }

    return navigatorRoutes.map((r) => _buildRoutePage(r, context, currentState));
  }

  @protected
  PageBuilder _pageBuilderForAppType(BuildContext context) {
    return _pageBuilder ??= _inferPageBuilder(context);
  }

  @protected
  Widget _buildErrorWidget(
    BuildContext buildContext,
    FailedMessage error,
    CurrentState currentState,
  ) {
    var msg = 'The state machine failed to process a message.\n\n'
        'Message: ${error.message.toString()}\n'
        'Receiving tree state: ${error.receivingState}\n\n'
        '${error.error.toString()}';
    return ErrorWidget.withDetails(message: msg);
  }

  Transition? _transition;
  @protected
  void _onTransition(CurrentState currentState, Transition transition) {
    _transition = transition;
    notifyListeners();
  }

  @protected
  bool _onPopPage(Route<dynamic> route, dynamic result) {
    _logger.finer('Popping page for state ${(route.settings as TreeStateRoute).stateKey}');
    if (!route.didPop(result)) return false;
    notifyListeners();
    return true;
  }

  Page<void> _buildRoutePage(
    TreeStateRoute route,
    BuildContext context,
    CurrentState currentState,
  ) {
    if (route.routePageBuilder != null) {
      return route.routePageBuilder!.call(context, TreeStateRoutingContext(currentState));
    } else if (route.routeBuilder != null) {
      var content = route.routeBuilder!.call(context, TreeStateRoutingContext(currentState));
      var pageBuilder = route.isPopup
          ? _dialogPageBuilder
          : _defaultPageBuilder ?? _pageBuilderForAppType(context);
      var buildFor = BuildForRoute(route);
      return pageBuilder(buildFor, _withDefaultScaffolding(buildFor, content));
    }

    // Should never happen because of validation in TreeStateRoute
    throw StateError(
        "TreeStateRoute for state ${route.stateKey} does not have routePageBuilder or a routeBuilder.");
  }

  Widget _withDefaultScaffolding(PageBuildFor buildFor, Widget content) {
    return _defaultScaffolding != null ? _defaultScaffolding!.call(buildFor, content) : content;
  }

  @protected
  Page<void> _createEmptyRoutesErrorPage(BuildContext context, List<StateKey> activeStates) {
    _logger.warning('No pages available to display active states [${activeStates.join(',')}]');
    Widget error = Container();
    assert(() {
      error = ErrorWidget.withDetails(
          message: 'No tree state routes are available to display any of the active states: '
              '${activeStates.map((s) => '"$s"').join(', ')}.\n\n'
              'Make sure to add a route that can display one of the active states to the $runtimeType.');
      return true;
    }());
    error = Center(child: error);
    return _pageBuilderForAppType(context).call(
      const BuildForError(),
      error,
    );
  }

  static Map<StateKey, TreeStateRoute> _mapRoutes(List<TreeStateRoute> pages) {
    var map = <StateKey, TreeStateRoute>{};
    for (var page in pages) {
      if (map.containsKey(page.stateKey)) {
        throw ArgumentError('Duplicate routes defined for state \'${page.stateKey}\'', 'pages');
      }
      map[page.stateKey] = page;
    }
    return map;
  }

  PageBuilder _inferPageBuilder(BuildContext context) {
    // May be null during testing
    Element? elem = context is Element ? context : null;
    if (elem != null) {
      if (elem.findAncestorWidgetOfExactType<MaterialApp>() != null) {
        _logger.info('Resolved MaterialApp. Will use MaterialPage pages.');
        return materialPageBuilder;
      } else if (elem.findAncestorWidgetOfExactType<CupertinoApp>() != null) {
        _logger.info('Resolved CupertinoApp. Will use CupertinoPage pages.');
        return cupertinoPageBuilder;
      }
    }

    _logger.info('Unable to resolve application type. Defaulting to MaterialPage pages.');
    return materialPageBuilder;
  }
}

class _PopupPage extends Page<void> {
  _PopupPage(this.popupContent);
  final Widget popupContent;

  @override
  Route<void> createRoute(BuildContext context) {
    return DialogRoute(context: context, builder: (c) => popupContent, settings: this);
  }
}

// A [RouterDelegate] that receives routing information from the state transitions of a
/// [TreeStateMachine].
///
/// As state transitions occur within the state machine, the router delegate will determine if there
/// are [TreeStateRoute]s that correspond to a active state of the state machine.  If a route is
/// available, it is displayed by the [Navigator] returned by [build].
class TreeStateRouterDelegate extends BaseTreeStateRouterDelegate {
  // TODO: make this delegate rebuild when routing config changes
  TreeStateRouterDelegate({
    required this.stateMachine,
    required super.config,
    super.displayStateMachineErrors,
  }) : super(
          logger: Logger('StateTreeRouterDelegate'),
        );

  /// The [TreeStateMachine] that provides the state transition  notifications to this router.
  final TreeStateMachine stateMachine;

  /// The key used for retrieving the current navigator.
  @override
  final navigatorKey = GlobalKey<NavigatorState>(debugLabel: 'StateTreeRouterDelegate');

  @override
  Widget build(BuildContext context) {
    var curState = stateMachine.currentState;
    if (curState != null) {
      _logger.fine('Creating pages for active states ${curState.activeStates.join(', ')}');
    }

    var pages = curState != null
        ? _buildActivePages(context, curState).toList()
        // build() may be called before the setNewRoutePath future completes, so we display a loading
        // indicator while that is in progress
        : [if (stateMachine.isStarting) _createLoadingPage(context)];

    if (pages.isEmpty) {
      pages = [_createEmptyRoutesErrorPage(context, curState?.activeStates ?? [])];
    }

    return _buildNavigatorWidget(pages, curState, provideCurrentState: curState != null);
  }

  @override
  Future<void> setNewRoutePath(TreeStateRouteInfo configuration) async {
    if (stateMachine.isStarted) {
      throw UnsupportedError('Routing after the state machine has started is not yet supported.');
    } else {
      await stateMachine.start(at: configuration.currentState);
    }
  }

  Page _createLoadingPage(BuildContext context) {
    var pageBuilder = _pageBuilderForAppType(context);
    return pageBuilder.call(
        const BuildForLoading(),
        const Center(
          child: Text('Loading'),
        ));
  }
}

/// A [RouterDelegate] that indented for use with a nested [Eo].
///
/// An application configures [NestedTreeStateRouterDelegate] that indicate how individual states in
/// the state machine should be visualized. This router does not need to be with a state machine
/// instance. because this router delegate is intended to be nested within an ancestor router configured
/// with a [TreeStateRouterDelegate]. This router will share the same state machine instance with
/// the ancestor [TreeStateRouterDelegate].
///
/// As state transitions occur within the parent state machine, this router delegate will determine
/// if there is a [TreeStateRoute] that corresponds to the an active state of the state machine. If a
/// route is available, it is displayed by the [Navigator] returned by [build].
class NestedTreeStateRouterDelegate extends BaseTreeStateRouterDelegate {
  NestedTreeStateRouterDelegate({
    required super.config,
    super.displayStateMachineErrors,
    this.supportsFinalPage = true,
  }) : super(
          logger: Logger('ChildTreeStateRouterDelegate'),
        );

  /// If `true` (the default), an error page will be displayed if the state machine reaches a final
  /// state, and there is no page in the pages list that can display that state.
  final bool supportsFinalPage;

  /// The key used for retrieving the current navigator.
  @override
  final navigatorKey = GlobalKey<NavigatorState>(debugLabel: 'ChildTreeStateRouterDelegate');

  @override
  Future<void> setNewRoutePath(TreeStateRouteInfo configuration) {
    throw UnsupportedError('Setting route paths is not currently supported');
  }

  @override
  Widget build(BuildContext context) {
    var stateMachineInfo = TreeStateMachineProvider.of(context);
    if (stateMachineInfo == null) {
      var message = 'Unable to find tree state machine in widget tree';
      _logger.warning(message);
      return ErrorWidget.withDetails(message: message);
    }

    var currentState = stateMachineInfo.currentState;
    var activeStates = currentState.activeStates;
    var pages = _buildActivePages(context, currentState).toList();
    if (pages.isEmpty) {
      if (currentState.stateMachine.isDone && !supportsFinalPage) {
        // If the current state machine is running as a nested machine, then there is likely a
        // Router with a NestedStateTreeRouterDelegate higher in the widget tree, which will render
        // a different page when the nested state machine finishes. In this case, a developer will
        // probably not add a page for the final state to this router delegate (since after all it
        // will never be displayed), so to avoid emitting warnings just use a transient page with
        // no visible content.
        pages = [MaterialPage(child: Container())];
      } else {
        _logger.warning(
          'No pages available to display active states ${currentState.activeStates.join(',')}',
        );
        pages = [_createEmptyRoutesErrorPage(context, activeStates)];
      }
    }

    return _buildNavigatorWidget(pages, currentState, provideCurrentState: false);
  }

  @override
  void _onTransition(CurrentState currentState, Transition transition) {
    if (!transition.isToFinalState || supportsFinalPage) {
      notifyListeners();
    }
  }
}

/// Overrides [resolve] to so that calls to [RouteTransitionRecord] that trigger animations are
/// rediirected to ones that do not. None of the core logic in DefaultTransitionDelegate (which is a
/// little tricky) is altered.
class _NoTransitionsTransitionDelegate extends DefaultTransitionDelegate {
  const _NoTransitionsTransitionDelegate();
  @override
  Iterable<RouteTransitionRecord> resolve({
    required List<RouteTransitionRecord> newPageRouteHistory,
    required Map<RouteTransitionRecord?, RouteTransitionRecord> locationToExitingPageRoute,
    required Map<RouteTransitionRecord?, List<RouteTransitionRecord>> pageRouteToPagelessRoutes,
  }) {
    var records = super.resolve(
      newPageRouteHistory: newPageRouteHistory.map(_NoTransitionRouteTransitionRecord.new).toList(),
      locationToExitingPageRoute: locationToExitingPageRoute,
      pageRouteToPagelessRoutes: pageRouteToPagelessRoutes,
    );
    // DefaultTransitionDelegate assumes records are _RouteEntry, so we need to unwrap
    // _NoTransitionRouteTransitionRecord before returning the results.
    return records.map((r) => r is _NoTransitionRouteTransitionRecord ? r.inner : r);
  }
}

/// Wraps a [RouteTransitionRecord] and redirects calls that trigger animations to calls that do not.
class _NoTransitionRouteTransitionRecord implements RouteTransitionRecord {
  _NoTransitionRouteTransitionRecord(this.inner);

  final RouteTransitionRecord inner;

  @override
  bool get isWaitingForEnteringDecision => inner.isWaitingForEnteringDecision;

  @override
  bool get isWaitingForExitingDecision => inner.isWaitingForExitingDecision;

  @override
  void markForAdd() => inner.markForAdd();

  @override
  // No animation.
  void markForPush() => inner.markForAdd();

  @override
  void markForComplete([result]) => inner.markForComplete(result);

  @override
  // No animation.
  void markForPop([result]) => inner.markForComplete(result);

  @override
  void markForRemove() => inner.markForRemove();

  @override
  Route get route => inner.route;
}
