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
  final List<StateRouteConfig> routes;
  final DefaultScaffoldingBuilder? defaultScaffolding;
  final DefaultPageBuilder? defaultPageBuilder;
  final bool enableTransitions;
}

abstract class TreeStateRouterDelegateBase
    extends RouterDelegate<TreeStateRouteInfo>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  TreeStateRouterDelegateBase({
    required this.config,
    required Logger log,
    this.displayStateMachineErrors = false,
  }) : _log = log;

  /// Configuration information for this router delegate describing the available routes.
  final TreeStateRouterDelegateConfig config;

  /// If `true`, this router delegate will display an [ErrorWidget] when the
  /// [TreeStateMachine.failedMessages] stream emits an event.
  ///
  /// This is primarily useful for debugging purposes.
  final bool displayStateMachineErrors;

  /// The most recent state machine transition that has occurred.
  Transition? _transition;

  final Logger _log;
  late final _routeMap = _mapRoutes(_routes);
  List<StateRouteConfig> get _routes => config.routes;
  DefaultScaffoldingBuilder? get _defaultScaffolding =>
      config.defaultScaffolding;
  DefaultPageBuilder? get _defaultPageBuilder => config.defaultPageBuilder;

  // Used to create Page<Object> when routes are unopinionated about which Page type to use.
  (PageBuilder pageBuilder, PageBuilder popupPageBuilder)? _pageBuilders;

  // Page<void> _dialogPageBuilder(PageBuildFor buildFor, Widget pageContent) {
  //   return _PopupPage(pageContent);
  // }

  Widget _buildNavigatorWidget(
    List<Page> pages,
    CurrentState? currentState, {
    required bool provideCurrentState,
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
      widget =
          TreeStateMachineProvider(currentState: currentState!, child: widget);
    }

    return widget;
  }

  /// Calculates the stack of routes that should display the current state of the state tree.
  ///
  /// Currently this returns a collection of 0 or 1 pages, but once a history feature is added to
  /// tree_state_machine, this will return a history stack which can be popped by the navigator.
  @protected
  Iterable<Page<void>> _buildActivePages(
      BuildContext context, CurrentState currentState) {
    /// Return the deepest page that maps to an active state. By deepest, we mean the page that
    /// maps to a state as far as possible from the root state. This gives the current leaf state
    /// priority in determining the page to display, followed by its parent state, etc.
    var activeRoutes =
        _findRoutesFor(currentState.activeStates.reversed).toList();
    var navigatorRoutes = activeRoutes.take(1);

    // If we have a popup route, attempt to find a route for one of the exiting states. This route
    // will be pushed on to the navigator below the popup route, so that the popup looks like it
    // appears over something.
    if (navigatorRoutes.isNotEmpty && navigatorRoutes.first.isPopup) {
      assert(_transition != null);
      var belowPopupRoutes = _findRoutesFor(_transition!.exitPath)
          .where((r) {
            // The exiting route can only be used if the route accesses state data from the
            // transition lca (or  higher), otherwise the state data that the route expects will not
            // be available. Even then, it may be risky to try an show the route, since the widget
            // content of the route may have additional unknown assumptions/dependencies on the
            // corresponding tree state being active.
            return !r.dependencies.contains(r.stateKey);
          })
          .take(1)
          .toList();

      if (belowPopupRoutes.isEmpty) {
        var error =
            "Popup route for '${navigatorRoutes.first.stateKey}' cannot be displayed because all "
            "exiting routes depend on data states below the least common ancestor state '${_transition!.lca}' for this "
            "transition: ";
        _log.severe(error);
        throw StateError(error);
      }

      navigatorRoutes = belowPopupRoutes.followedBy(navigatorRoutes);
    }

    return navigatorRoutes
        .map((r) => _buildRoutePage(r, context, currentState));
  }

  @protected
  PageBuilder _pageBuilderForAppType(BuildContext context) {
    var (pageBuilder, _) = _pageBuilders ??= _inferPageBuilders(context);
    return pageBuilder;
  }

  @protected
  PageBuilder _popupBuilderForAppType(BuildContext context) {
    var (_, popupPageBuilder) = _pageBuilders ??= _inferPageBuilders(context);
    return popupPageBuilder;
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

  @protected
  void _onTransition(CurrentState currentState, Transition transition) {
    _transition = transition;
    // Only notify (i.e. rebuild the navigator) if the transition applies to one of the routes.
    var shouldNotify = transition.path.any(_routeMap.containsKey);
    if (shouldNotify) {
      notifyListeners();
    }
  }

  @protected
  bool _onPopPage(Route<dynamic> route, dynamic result) {
    _log.finer(
        'Popping page for state ${(route.settings as StateRoute).stateKey}');
    if (!route.didPop(result)) return false;
    notifyListeners();
    return true;
  }

  Page<void> _buildRoutePage(
    StateRouteConfig route,
    BuildContext context,
    CurrentState currentState,
  ) {
    if (route.routePageBuilder != null) {
      return route.routePageBuilder!
          .call(context, StateRoutingContext(currentState));
    } else if (route.routeBuilder != null) {
      var content =
          route.routeBuilder!.call(context, StateRoutingContext(currentState));
      var pageBuilder = route.isPopup
          ? _popupBuilderForAppType(context)
          : _defaultPageBuilder ?? _pageBuilderForAppType(context);
      var buildFor = BuildForRoute(route);
      return pageBuilder(buildFor, _withDefaultScaffolding(buildFor, content));
    }

    // Should never happen because of validation in TreeStateRoute
    throw StateError(
        "TreeStateRoute for state ${route.stateKey} does not have routePageBuilder or a routeBuilder.");
  }

  Widget _withDefaultScaffolding(PageBuildFor buildFor, Widget content) {
    return _defaultScaffolding != null
        ? _defaultScaffolding!.call(buildFor, content)
        : content;
  }

  @protected
  Page<void> _createEmptyRoutesErrorPage(
      BuildContext context, List<StateKey> activeStates) {
    _log.warning(
        'No pages available to display active states [${activeStates.join(',')}]');
    Widget error = Container();
    assert(() {
      error = ErrorWidget.withDetails(
          message:
              'No tree state routes are available to display any of the active states: '
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

  Iterable<StateRouteConfig> _findRoutesFor(Iterable<StateKey> keys) {
    return keys
        .map((stateKey) => MapEntry<StateKey, StateRouteConfig?>(
            stateKey, _routeMap[stateKey]))
        .where((entry) => entry.value != null)
        .map((entry) => entry.value!);
  }

  static Map<StateKey, StateRouteConfig> _mapRoutes(
      List<StateRouteConfig> routes) {
    var map = <StateKey, StateRouteConfig>{};
    for (var route in routes) {
      if (map.containsKey(route.stateKey)) {
        throw ArgumentError(
            'Duplicate routes defined for state \'${route.stateKey}\'',
            'pages');
      }
      map[route.stateKey] = route;
    }
    return map;
  }

  (PageBuilder pageBuilder, PageBuilder popupPageBuilder) _inferPageBuilders(
      BuildContext context) {
    // May be null during testing
    Element? elem = context is Element ? context : null;
    if (elem != null) {
      if (elem.findAncestorWidgetOfExactType<MaterialApp>() != null) {
        _log.info('Resolved MaterialApp. Will use MaterialPage pages.');
        return (materialPageBuilder, materialPopupPageBuilder);
      } else if (elem.findAncestorWidgetOfExactType<CupertinoApp>() != null) {
        _log.info('Resolved CupertinoApp. Will use CupertinoPage pages.');
        return (cupertinoPageBuilder, materialPopupPageBuilder);
      }
    }

    _log.info(
        'Unable to resolve application type. Defaulting to MaterialPage pages.');
    return (materialPageBuilder, materialPopupPageBuilder);
  }
}

// A [RouterDelegate] that receives routing information from the state transitions of a
/// [TreeStateMachine].
///
/// As state transitions occur within the state machine, the router delegate will determine if there
/// are [StateRoute]s that correspond to a active state of the state machine.  If a route is
/// available, it is displayed by the [Navigator] returned by [build].
class TreeStateRouterDelegate extends TreeStateRouterDelegateBase {
  // TODO: make this delegate rebuild when routing config changes
  TreeStateRouterDelegate({
    required this.stateMachine,
    // TODO: validate data dependencies (dependencies must be self or ancestor states)
    required super.config,
    super.displayStateMachineErrors,
  }) : super(
          log: Logger('StateTreeRouterDelegate'),
        );

  /// The [TreeStateMachine] that provides the state transition  notifications to this router.
  final TreeStateMachine stateMachine;

  /// The key used for retrieving the current navigator.
  @override
  final navigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'TreeStateRouterDelegate');

  @override
  Widget build(BuildContext context) {
    var curState = stateMachine.currentState;
    if (curState != null) {
      _log.fine(
          'Creating pages for active states ${curState.activeStates.join(', ')}');
    }

    var pages = curState != null
        ? _buildActivePages(context, curState).toList()
        // build() may be called before the setNewRoutePath future completes, so we display a loading
        // indicator while that is in progress
        : [if (stateMachine.lifecycle.isStarting) _createLoadingPage(context)];

    if (pages.isEmpty) {
      pages = [
        _createEmptyRoutesErrorPage(context, curState?.activeStates ?? [])
      ];
    }

    return _buildNavigatorWidget(pages, curState,
        provideCurrentState: curState != null);
  }

  @override
  Future<void> setNewRoutePath(TreeStateRouteInfo configuration) async {
    if (stateMachine.lifecycle.isStarted) {
      throw UnsupportedError(
          'Routing after the state machine has started is not yet supported.');
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

/// The [RouterDelegate] used by [NestedTreeStateRouter].
///
/// An application configures [NestedTreeStateRouterDelegate] that indicate how individual states in
/// the state machine should be visualized. This router does not need to be with a state machine
/// instance. because this router delegate is intended to be nested within an ancestor router
/// configured with a [TreeStateRouterDelegate]. This router will share the same state machine
/// instance with the ancestor [TreeStateRouterDelegate].
///
/// As state transitions occur within the parent state machine, this router delegate will determine
/// if there is a [StateRoute] that corresponds to the an active state of the state machine. If
/// a route is available, it is displayed by the [Navigator] returned by [build].
class NestedTreeStateRouterDelegate extends TreeStateRouterDelegateBase {
  NestedTreeStateRouterDelegate({
    required super.config,
    super.displayStateMachineErrors,
    this.supportsFinalRoute = true,
  }) : super(
          log: Logger('ChildTreeStateRouterDelegate'),
        );

  /// If `true` (the default), an error page will be displayed if the state machine reaches a final
  /// state, and there is no route that can display that state.
  final bool supportsFinalRoute;

  /// The key used for retrieving the current navigator.
  @override
  final navigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'ChildTreeStateRouterDelegate');

  @override
  Future<void> setNewRoutePath(TreeStateRouteInfo configuration) {
    throw UnsupportedError('Setting route paths is not currently supported');
  }

  @override
  Widget build(BuildContext context) {
    var stateMachineInfo = TreeStateMachineProvider.of(context);
    if (stateMachineInfo == null) {
      var message = 'Unable to find tree state machine in widget tree';
      _log.warning(message);
      return ErrorWidget.withDetails(message: message);
    }

    var currentState = stateMachineInfo.currentState;
    var activeStates = currentState.activeStates;
    var pages = _buildActivePages(context, currentState).toList();
    if (pages.isEmpty) {
      if (currentState.stateMachine.isDone && !supportsFinalRoute) {
        // If the current state machine is running as a nested machine, then there is likely a
        // Router with a NestedStateTreeRouterDelegate higher in the widget tree, which will render
        // a different page when the nested state machine finishes. In this case, a developer will
        // probably not add a page for the final state to this router delegate (since after all it
        // will never be displayed), so to avoid emitting warnings just use a transient page with
        // no visible content.
        pages = [MaterialPage(child: Container())];
      } else {
        _log.warning(
          'No pages available to display active states ${currentState.activeStates.join(',')}',
        );
        pages = [_createEmptyRoutesErrorPage(context, activeStates)];
      }
    }

    return _buildNavigatorWidget(pages, currentState,
        provideCurrentState: false);
  }

  @override
  void _onTransition(CurrentState currentState, Transition transition) {
    _transition = transition;
    if (!transition.isToFinalState || supportsFinalRoute) {
      super._onTransition(currentState, transition);
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
    required Map<RouteTransitionRecord?, RouteTransitionRecord>
        locationToExitingPageRoute,
    required Map<RouteTransitionRecord?, List<RouteTransitionRecord>>
        pageRouteToPagelessRoutes,
  }) {
    var records = super.resolve(
      newPageRouteHistory: newPageRouteHistory
          .map(_NoTransitionsRouteTransitionRecord.new)
          .toList(),
      locationToExitingPageRoute: locationToExitingPageRoute,
      pageRouteToPagelessRoutes: pageRouteToPagelessRoutes,
    );
    // DefaultTransitionDelegate assumes records are _RouteEntry, so we need to unwrap
    // _NoTransitionRouteTransitionRecord before returning the results.
    return records
        .map((r) => r is _NoTransitionsRouteTransitionRecord ? r.inner : r);
  }
}

/// Wraps a [RouteTransitionRecord] and redirects calls that trigger animations to calls that do not.
class _NoTransitionsRouteTransitionRecord implements RouteTransitionRecord {
  _NoTransitionsRouteTransitionRecord(this.inner);

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
