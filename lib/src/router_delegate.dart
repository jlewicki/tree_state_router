import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_machine/build.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/route_table.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'package:tree_state_router/src/pages.dart';
import 'package:tree_state_router/src/widgets/state_machine_error.dart';
import 'package:tree_state_router/src/widgets/state_machine_events.dart';

/// The error thrown when an unrecoverable error occurs with a
/// [TreeStateRouter], typically caused by a configuration error that must be
/// addressed by a developer.
class TreeStateRouterError extends Error {
  TreeStateRouterError(this.message);
  final String message;
}

class TreeStateRouterDelegateConfig {
  TreeStateRouterDelegateConfig(
    this.routes, {
    this.defaultPageBuilder,
    this.defaultScaffolding,
    this.enableTransitions = true,
    this.enablePlatformRouting = false,
  });
  final List<StateRouteConfig> routes;
  final DefaultScaffoldingBuilder? defaultScaffolding;
  final DefaultPageBuilder? defaultPageBuilder;
  final bool enableTransitions;
  final bool enablePlatformRouting;
}

// Error handling:
//
// * Assertions are used for internal invariants, not to validate configuration
// * RouterDelegates will throw TreeStateRouterError for errors due to route
//   configuration errors
// * Errors detected during build are presented as a page in the router
// * Errors emitted from the state machine are detected and presented as a page
//   in the router
abstract class TreeStateRouterDelegateBase
    extends RouterDelegate<TreeStateRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  TreeStateRouterDelegateBase({
    required this.config,
    required Logger log,
    this.displayStateMachineErrors = false,
  }) : _log = log;

  /// Configuration information for this router delegate describing the
  /// vailable routes.
  final TreeStateRouterDelegateConfig config;

  /// If `true`, this router delegate will display an [ErrorWidget] when the
  /// [TreeStateMachine.failedMessages] stream emits an event.
  ///
  /// This is primarily useful for debugging purposes.
  final bool displayStateMachineErrors;

  /// The most recent state machine transition that has occurred.
  Transition? _transition;

  final Logger _log;

  /// Catalogs errors that can be thrown by the router delegates
  late final _RouterErrors _errors = _RouterErrors(_log);

  /// The routes routed by this delegate, indexed by state key.
  late final _routeMap = _mapRoutes(config.routes);

  // Used to create Page<Object> when routes are unopinionated about which Page
  // type to use.
  (PageBuilder pageBuilder, PageBuilder popupPageBuilder)? _pageBuilders;

  Widget _buildNavigatorWidget(
    List<Page> pages,
    CurrentState? currentState, {
    required bool provideCurrentState,
    StateKey? transitionEventRootState,
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
        transitionsRootKey: transitionEventRootState,
        child: displayStateMachineErrors
            ? StateMachineErrorBuilder(
                errorBuilder: _stateMachineErrorBuilder,
                child: widget,
              )
            : widget,
      );
    }

    if (provideCurrentState && currentState != null) {
      widget = TreeStateMachineProvider(
        currentState: currentState,
        child: widget,
      );
    }

    return widget;
  }

  /// Calculates the stack of routes that should display the current state of
  /// the state tree.
  ///
  /// Currently this returns a collection of 0 or 1 pages, but once a history
  /// feature is added to tree_state_machine, this will return a history stack
  /// which can be popped by the navigator.
  @protected
  Iterable<Page<void>> _buildActivePages(
    BuildContext context,
    CurrentState currentState,
  ) {
    _log.fine(() => 'Creating pages for active states: '
        '${currentState.activeStates.join(', ')}');

    Iterable<StateRouteConfig> navigatorRoutes = _activeRoutes(currentState);

    // If we have a popup route, attempt to find a route for one of the exiting
    // states. This route will be pushed on to the navigator below the popup
    // route, so that the popup looks like it appears over something.
    if (navigatorRoutes.isNotEmpty && navigatorRoutes.first.isPopup) {
      assert(_transition != null);
      var belowPopupRoutes = _findRoutesFor(_transition!.exitPath)
          .where((r) {
            // The exiting route can only be used if the route accesses state
            // data from the transition lca (or  higher), otherwise the state
            // data that the route expects will not be available. Even then, it
            // may be risky to try an show the route, since the widget content
            // of the route may have additional unknown assumptions/dependencies
            // on the corresponding tree state being active.
            return !r.dependencies.contains(r.stateKey);
          })
          .take(1)
          .toList();

      if (belowPopupRoutes.isEmpty) {
        throw _errors.invalidPopupRoute(
          navigatorRoutes.first.stateKey,
          _transition!,
        );
      }

      navigatorRoutes = belowPopupRoutes.followedBy(navigatorRoutes);
    }

    return navigatorRoutes
        .map((r) => _buildRoutePage(r, context, currentState));
  }

  /// Return the deepest route that maps to an active state. By deepest, we mean
  /// the route that maps to a state as far as possible from the root state.
  /// This gives the current leaf state priority in determining the route to
  /// display, followed by its parent state, etc.
  List<StateRouteConfig> _activeRoutes(CurrentState currentState) {
    // Is the order right here?
    var activeRoutes = _findRoutesFor(currentState.activeStates.reversed);
    return activeRoutes.take(1).toList();
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
  Widget _stateMachineErrorBuilder(
    BuildContext buildContext,
    FailedMessage failedMessage,
    CurrentState currentState,
  ) {
    throw _errors.stateMachineFailedMessage(failedMessage);
  }

  @protected
  void _onTransition(CurrentState currentState, Transition transition) {
    _transition = transition;
    // Only notify (i.e. rebuild the navigator) if the transition applies to one
    // of the routes.
    var shouldNotify = transition.path.any(_routeMap.containsKey);
    if (shouldNotify) {
      notifyListeners();
    }
  }

  @protected
  bool _onPopPage(Route<dynamic> route, dynamic result) {
    _log.finer(() =>
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
    var buildFor = BuildForRoute(route.stateKey, route.isPopup);
    var routingContext = StateRoutingContext(currentState);
    if (route.routePageBuilder != null) {
      return route.routePageBuilder!.call(
          context,
          (buildPageContent) => _withDefaultScaffolding(
                buildFor,
                buildPageContent(context, routingContext),
              ));
    } else if (route.routeBuilder != null) {
      var content = route.routeBuilder!.call(context, routingContext);
      var appPageBuilder = route.isPopup
          ? _popupBuilderForAppType(context)
          : _pageBuilderForAppType(context);
      var pageBuilder = route.isPopup
          ? appPageBuilder
          : config.defaultPageBuilder ?? _pageBuilderForAppType(context);
      var pageContent = _withDefaultScaffolding(buildFor, content);
      return pageBuilder(buildFor, pageContent) ??
          appPageBuilder(buildFor, pageContent);
    }

    // Should never happen because of validation in TreeStateRoute
    throw _errors.missingBuilder(route.stateKey);
  }

  Widget _withDefaultScaffolding(PageBuildFor buildFor, Widget content) {
    return config.defaultScaffolding?.call(buildFor, content) ?? content;
  }

  @protected
  Page<void> _createErrorPage(BuildContext context, Object exception) {
    var appPageBuilder = _pageBuilderForAppType(context);
    var pageContent = exception is TreeStateRouterError
        ? ErrorWidget.withDetails(message: exception.message)
        : ErrorWidget(exception);
    var buildFor = BuildForError(exception);
    return config.defaultPageBuilder?.call(buildFor, pageContent) ??
        appPageBuilder(buildFor, pageContent);
  }

  Iterable<StateRouteConfig> _findRoutesFor(Iterable<StateKey> keys) {
    return keys
        .map((stateKey) => MapEntry<StateKey, StateRouteConfig?>(
            stateKey, _routeMap[stateKey]))
        .where((entry) => entry.value != null)
        .map((entry) => entry.value!);
  }

  Map<StateKey, StateRouteConfig> _mapRoutes(List<StateRouteConfig> routes) {
    var map = <StateKey, StateRouteConfig>{};
    for (var route in routes) {
      if (map.containsKey(route.stateKey)) {
        throw _errors.duplicateRoutes(route.stateKey);
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

/// A [RouterDelegate] that receives routing information from the state
/// transitions of a [TreeStateMachine].
///
/// As state transitions occur within the state machine, the router delegate
/// will determine if there are [StateRoute]s that correspond to a active state
/// of the state machine.  If a route is available, it is displayed by the
///  [Navigator] returned by [build].
class TreeStateRouterDelegate extends TreeStateRouterDelegateBase {
  // TODO: make this delegate rebuild when routing config changes
  TreeStateRouterDelegate({
    required this.stateMachine,
    // TODO: validate data dependencies (dependencies must be self or ancestor states)
    required super.config,
    required RouteTable routeTable,
    super.displayStateMachineErrors,
  })  : _routeTable = routeTable,
        super(
          log: Logger('TreeStateRouterDelegate'),
        ) {
    if (!config.enablePlatformRouting) {
      // If platform routing is disabled, there will be no call to
      // setNewRoutePath on app start, so we need to set the current
      // configuration (and consequently start the state machine) here.
      _setCurrentConfiguration(TreeStateRoutePath.empty);
    }
  }

  /// The [TreeStateMachine] that provides the state transition notifications to
  /// this router.
  final TreeStateMachine stateMachine;

  final RouteTable _routeTable;

  /// The key used for retrieving the current navigator.
  @override
  final navigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'TreeStateRouterDelegate');

  @override
  // We have to implement this for the current routing configuration to be reported to the platform,
  // and consequently show up in the browser URL
  TreeStateRoutePath? get currentConfiguration =>
      config.enablePlatformRouting ? _currentConfiguration : null;

  TreeStateRoutePath? _currentConfiguration;

  // Called when new route information has been provided by the platform (via deep linking or
  // browser URI)
  @override
  Future<void> setNewRoutePath(TreeStateRoutePath configuration) async {
    if (currentConfiguration == configuration) {
      return done;
    }

    return _setCurrentConfiguration(configuration);
  }

  @override
  Widget build(BuildContext context) {
    assert(
        stateMachine.lifecycle.isStarting || stateMachine.lifecycle.isStarted);

    var pages = <Page>[];
    var currentState = stateMachine.currentState;
    try {
      pages = currentState != null
          ? _buildActivePages(context, currentState).toList()
          : [
              // build() may be called before the setNewRoutePath future completes, so we display a
              // loading indicator while that is in progress
              if (stateMachine.lifecycle.isStarting) _createLoadingPage(context)
            ];

      if (pages.isEmpty) {
        throw _errors.noPagesForActiveStates(currentState?.activeStates ?? []);
      }
    } catch (ex) {
      pages = [_createErrorPage(context, ex)];
    }

    return _buildNavigatorWidget(
      pages,
      currentState,
      provideCurrentState: currentState != null,
    );
  }

  @override
  void _onTransition(CurrentState currentState, Transition transition) {
    _transition = transition;
    var routeMatches = _routeTable.routePathForTransition(transition);
    _setCurrentConfiguration(routeMatches);
  }

  Future<void> _setCurrentConfiguration(TreeStateRoutePath configuration) {
    //_currentConfiguration = configuration;
    return _startOrUpdateStateMachine(configuration).then((config) {
      _currentConfiguration = config;
      notifyListeners();
    });
  }

  Future<TreeStateRoutePath> _startOrUpdateStateMachine(
    TreeStateRoutePath configuration,
  ) {
    if (stateMachine.lifecycle.isStarted && stateMachine.currentState != null) {
      var activeStates = stateMachine.currentState!.activeStates;
      var allRoutesActive =
          configuration.routes.every((r) => activeStates.contains(r.stateKey));
      if (allRoutesActive) {
        // All the routes in the requested configuration correspond to an active state in the
        // state machine, so
        return SynchronousFuture(configuration);
      } else if (configuration.isDeepLinkable) {
        // TODO: Add a special deep-link routing message, and a filter that can handle the messge
        // and force the goTo
        return SynchronousFuture(configuration);
      } else {
        // Return current configuration, not requested one, since the requested one is not
        // deep-linkable.
        return SynchronousFuture(_currentConfiguration!);
      }
    }

    var isStartable = stateMachine.lifecycle.isConstructed ||
        stateMachine.lifecycle.isStopped;

    if (isStartable) {
      var startAt =
          configuration.isDeepLinkable ? configuration.end.stateKey : null;
      _log.fine(
          "Starting state machine ${startAt != null ? "at: '$startAt'" : ''}");
      var initTransFuture = stateMachine.transitions.first;
      stateMachine.start(at: startAt);
      return initTransFuture.then((initTrans) {
        _log.fine("Started state machine. Current state: '${initTrans.to}'");
        return _routeTable.routePathForTransition(initTrans);
      });
    }

    _log.warning('_startOrUpdateStateMachine with null configuration');
    return SynchronousFuture(configuration);
  }

  Page _createLoadingPage(BuildContext context) {
    var pageBuilder = _pageBuilderForAppType(context);
    return pageBuilder.call(
        const BuildForLoading(),
        const Center(
          child: Text('Loading'),
        ));
  }

  static final done = SynchronousFuture<void>(null);
}

/// The [RouterDelegate] used by [DescendantStatesRouter]. The routes provided to this router
/// delegate via [config] must correspond to descendant states of [anchorKey].
///
/// This router requires that an inherited state machine be available in the widget tree via
/// [TreeStateMachineProvider].
class DescendantStatesRouterDelegate extends TreeStateRouterDelegateBase {
  DescendantStatesRouterDelegate({
    required super.config,
    required this.anchorKey,
    super.displayStateMachineErrors,
    this.supportsFinalRoute = true,
  }) : super(
          log: Logger('ChildTreeStateRouterDelegate'),
        );

  /// {@template NestedTreeStateRouterDelegate.anchorKey}
  /// Identifies the tree state that anchors the state transitions that are routed by this router.
  ///
  /// Only state transitions such that this state remains active are routed. In other words, routing
  /// only occurs if the transition is between two descendants of this state.
  /// {@endtemplate}
  final StateKey anchorKey;

  /// If `true` (the default), an error page will be displayed if the state machine reaches a final
  /// state, and there is no route that can display that state.
  final bool supportsFinalRoute;

  /// Records if nested route topology has been validated
  bool _nestedRoutesValidated = false;

  /// The key used for retrieving the current navigator.
  @override
  final navigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'ChildTreeStateRouterDelegate');

  @override
  Future<void> setNewRoutePath(TreeStateRoutePath configuration) {
    throw UnsupportedError('Setting route paths is not currently supported');
  }

  @override
  Widget build(BuildContext context) {
    List<Page> pages = [];
    CurrentState? currentState;

    try {
      var stateMachineInfo = TreeStateMachineProvider.of(context);
      if (stateMachineInfo == null) {
        throw _errors.missingStateMachine();
      }

      // Verify that routed states are all descendant states of parentKey
      if (!_nestedRoutesValidated) {
        _validateNestedRoutes(
            stateMachineInfo.currentState.stateMachine.rootNode);
        _nestedRoutesValidated = true;
      }

      currentState = stateMachineInfo.currentState;
      pages = _buildActivePages(context, currentState).toList();
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
          throw _errors.noPagesForActiveStates(currentState.activeStates);
        }
      }
    } catch (ex) {
      pages = [_createErrorPage(context, ex)];
    }

    return _buildNavigatorWidget(
      pages,
      currentState,
      provideCurrentState: false,
      transitionEventRootState: anchorKey,
    );
  }

  void _validateNestedRoutes(RootNodeInfo rootNode) {
    var routedStates = rootNode
        .selfAndDescendants()
        .where((e) => _routeMap.containsKey(e.key));

    List<StateKey> invalidRoutes = [];
    for (var routedState in routedStates) {
      var ancestor =
          routedState.ancestors().firstWhereOrNull((e) => e.key == anchorKey);
      if (ancestor == null) {
        invalidRoutes.add(routedState.key);
      }
    }

    if (invalidRoutes.isNotEmpty) {
      throw _errors.nestedRoutesAreNotDescendantsOfParent(
          anchorKey, invalidRoutes);
    }
  }

  @override
  void _onTransition(CurrentState currentState, Transition transition) {
    _transition = transition;
    if (!transition.isToFinalState || supportsFinalRoute) {
      super._onTransition(currentState, transition);
    }
  }
}

/// The [RouterDelegate] used by [DescendantStatesRouter] to route states in a nested state machine.
///
/// The state identified by [machineStateKey] must be nested machine state.
class NestedMachineRouterDelegate extends TreeStateRouterDelegateBase {
  NestedMachineRouterDelegate({
    required super.config,
    required this.machineStateKey,
    super.displayStateMachineErrors,
  }) : super(
          log: Logger('NestedMachineRouterDelegate'),
        );

  /// {@template NestedMachineRouterDelegate.machineStateKey}
  /// Identifies the state that is the host state for a nested state machine.
  /// {@endtemplate}
  DataStateKey<MachineTreeStateData> machineStateKey;

  /// The key used for retrieving the current navigator.
  @override
  final navigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'NestedMachineRouterDelegate');

  @override
  Future<void> setNewRoutePath(TreeStateRoutePath configuration) {
    throw UnsupportedError('Setting route paths is not currently supported');
  }

  @override
  Widget build(BuildContext context) {
    List<Page> pages = [];
    CurrentState? currentState;
    try {
      var stateMachineInfo = TreeStateMachineProvider.of(context);
      if (stateMachineInfo == null) {
        throw _errors.missingStateMachine();
      }

      currentState = stateMachineInfo.currentState;
      var nestedMachineData = currentState.dataValue(machineStateKey);
      if (nestedMachineData == null) {
        throw _errors.noNestedStateMachineData(currentState.activeStates);
      }

      currentState = nestedMachineData.nestedCurrentState;
      pages = _buildActivePages(context, currentState).toList();
    } catch (ex) {
      pages = [_createErrorPage(context, ex)];
    }

    return _buildNavigatorWidget(
      pages,
      currentState,
      provideCurrentState: true,
    );
  }

  @override
  void _onTransition(CurrentState currentState, Transition transition) {
    // Do not notify when the nested state machine reaches a final state. If we were to notify, then
    // we would schedule a call to build for this router.  However, the parent machine tree state
    // that owns the nested state machine transition to a different state when the final state is
    // reached, which means that when the scheduled build actually runs,
    // currentState.dataValue<NestedMachineData>() will no longer find a nested state machine, and
    // the build method will fail.
    if (!transition.isToFinalState) {
      notifyListeners();
    }
  }
}

class _RouterErrors {
  _RouterErrors(this._log);

  final Logger _log;

  TreeStateRouterError missingStateMachine() {
    var message = 'Unable to find tree state machine in widget tree';
    _log.severe(message);
    return TreeStateRouterError(message);
  }

  TreeStateRouterError duplicateRoutes(StateKey duplicateKey) {
    var message =
        "Duplicate routes defined for state '$duplicateKey'. A state can only "
        "have a single route associatd with it.";
    _log.severe(message);
    return TreeStateRouterError(message);
  }

  TreeStateRouterError missingBuilder(StateKey routeKey) {
    var message =
        "TreeStateRoute for state '$routeKey' does not have routePageBuilder "
        "or a routeBuilder.";
    _log.severe(message);
    return TreeStateRouterError(message);
  }

  TreeStateRouterError invalidPopupRoute(
      StateKey popupRouteKey, Transition transition) {
    var message =
        "Popup route for '$popupRouteKey' cannot be displayed because all "
        "exiting routes depend on data states below the least common ancestor "
        "state '${transition.lca}' for this transition: \n\n"
        "";
    _log.severe(message);
    return TreeStateRouterError(message);
  }

  TreeStateRouterError noPagesForActiveStates(List<StateKey> activeStates) {
    var message =
        'No tree state routes are available to display any of the active '
        'states:\n\n'
        '${activeStates.map((s) => '"$s"').join(', ')}.\n\n'
        'Make sure to add a route that can display one of the active states to '
        'the router.';
    _log.severe(message);
    return TreeStateRouterError(message);
  }

  TreeStateRouterError stateMachineFailedMessage(FailedMessage error) {
    var message = 'The state machine failed to process a message.\n\n'
        'Message: ${error.message.toString()}\n'
        'Receiving tree state: ${error.receivingState} \n\n'
        '${error.error.toString()}';
    _log.severe(message);
    return TreeStateRouterError(message);
  }

  TreeStateRouterError nestedRoutesAreNotDescendantsOfParent(
    StateKey parentKey,
    List<StateKey> routedStates,
  ) {
    var message = 'Unable to display a route page for nested router with '
        "for parent state '$parentKey', because the following routed states are "
        'not descendants of the parent state:\n'
        '${routedStates.join('\n')}';
    _log.severe(message);
    return TreeStateRouterError(message);
  }

  TreeStateRouterError noNestedStateMachineData(List<StateKey> activeStates) {
    var message = 'Unable to find nested machine data in active states '
        '${activeStates.map((e) => "'${e.toString()}'").join(', ')}.';
    _log.severe(message);
    return TreeStateRouterError(message);
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
