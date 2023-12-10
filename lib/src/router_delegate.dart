import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/pages.dart';
import 'package:tree_state_router/src/parser.dart';
import 'package:tree_state_router/src/provider.dart';
import 'package:tree_state_router/tree_state_router.dart';

abstract class BaseTreeStateRouterDelegate extends RouterDelegate<TreeStateRouteInfo>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  BaseTreeStateRouterDelegate({
    required this.routerConfig,
    required Logger logger,
    this.displayStateMachineErrors = false,
  }) : _logger = logger;

  /// The list of routes that can be displayed by this router delegate.
  final TreeStateRouting routerConfig;

  List<TreeStateRoute> get _routes => routerConfig.routes;

  /// If `true`, this router delegate will display an [ErrorWidget] when the
  /// [TreeStateMachine.failedMessages] stream emits an event.
  ///
  /// This is primarily useful for debugging purposes.
  final bool displayStateMachineErrors;

  final Logger _logger;
  late final Map<StateKey, TreeStateRoute> _routeMap = _mapRoutes(_routes);

  // Used to create Page<Object> when routes are unopinionated about which Page type to use.
  PageBuilder? _pageBuilder;

  Widget _buildNavigatorWidget(
    List<Page> pages,
    CurrentState? currentState, {
    required bool provideCurrentState,
  }) {
    Widget widget = Navigator(
      key: navigatorKey,
      pages: pages,
      onPopPage: _onPopPage,
    );

    if (currentState != null) {
      widget = TreeStateMachineEvents(
        onTransition: _onTransition,
        child: displayStateMachineErrors
            ? TreeStateMachineErrorDisplay(
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

  /// Calculates the stack of routes that should display the current state of the state tree.
  ///
  /// Currently this returns a collection of 0 or 1 pages, but once a history feature is added to
  /// tree_state_machine, this will return a history stack which can be popped by the navigator.
  @protected
  Iterable<Page<void>> _buildActivePages(BuildContext context, CurrentState currentState) {
    /// Return the deepest page that maps to an active state. By deepest, we mean the page that
    /// maps to a state as far as possible from the root state. This gives the current leaf state
    /// priority in determining the page to display, followed by its parent state, etc.
    var activeRoute = currentState.activeStates.reversed
        .map((stateKey) => MapEntry<StateKey, TreeStateRoute?>(stateKey, _routeMap[stateKey]))
        .where((entry) => entry.value != null)
        .map((entry) => entry.value!)
        .firstOrNull;
    return activeRoute != null ? [_buildRoutePage(activeRoute, context, currentState)] : [];
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

  @protected
  void _onTransition(CurrentState currentState, Transition transition) {
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
      var pageBuilder = routerConfig.defaultPageBuilder ?? _pageBuilderForAppType(context);
      var buildFor = BuildForTreeState(route.stateKey);
      return pageBuilder(buildFor, _withDefaultScaffolding(buildFor, content));
    }

    // Should never happen because of validation in TreeStateRoute
    throw StateError(
        "TreeStateRoute for state ${route.stateKey} does not have routePageBuilder or a routeBuilder.");
  }

  Widget _withDefaultScaffolding(PageBuildFor buildFor, Widget content) {
    return routerConfig.defaultLayout != null
        ? routerConfig.defaultLayout!.call(buildFor, content)
        : content;
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
        throw ArgumentError('Duplicate pages defined for state ${page.stateKey}', 'pages');
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

// A [RouterDelegate] that receives routing information from the state transitions of a
/// [TreeStateMachine].
///
/// An application configures [StateTreeRouterDelegate] with a [stateMachine], and a list of
/// [TreeStatePage]s that indicate how individual states in the state machine should be
/// visualized.
///
/// As state transitions occur within the state machine, the router delegate will determine there is
/// a [TreeStatePage] that corresponds to the an active state of the state machine.  If a page is
/// available, it is displayed by the [Navigator] returned by [build].
class TreeStateRouterDelegate extends BaseTreeStateRouterDelegate {
  // TODO: make this delegate rebuild when routing config changes
  TreeStateRouterDelegate({
    required this.stateMachine,
    required super.routerConfig,
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
      _logger.fine('Creating pages for active states ${curState.activeStates.join(',')}');
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

// A widget for receiving notifications from a [TreeStateMachine].
///
/// The state machine providing the events is obtained using [TreeStateMachineProvider.of].
class TreeStateMachineEvents extends StatefulWidget {
  const TreeStateMachineEvents({
    super.key,
    required this.child,
    this.transitionRootKey,
    this.onTransition,
    this.onFailedMessage,
  });

  /// The widget below this widget in the tree.
  final Widget child;

  /// Optional state key indicating a state that is used as a root for transition events.
  ///
  /// If provided, [onTransition] will be called only for transitions that occur between states that
  /// are desecendant of the transition root.
  final StateKey? transitionRootKey;

  /// Called when a state transition has occurred within the state machine.
  final void Function(CurrentState, Transition)? onTransition;

  /// Called when an error occurs when the state machine processes a message.
  final void Function(CurrentState, FailedMessage)? onFailedMessage;

  @override
  State createState() => _TreeStateMachineEventsState();
}

class _TreeStateMachineEventsState extends State<TreeStateMachineEvents> {
  StreamSubscription? _transitionSubscription;
  StreamSubscription? _errorSubscription;

  @override
  void didUpdateWidget(TreeStateMachineEvents oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onTransition != oldWidget.onTransition ||
        widget.onFailedMessage != oldWidget.onFailedMessage ||
        widget.transitionRootKey != oldWidget.transitionRootKey) {
      _unsubscribe();
      _subscribe();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _unsubscribe();
    _subscribe();
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _subscribe() {
    var stateMachineContext = TreeStateMachineProvider.of(context);
    if (stateMachineContext == null) {
      return;
    }

    var currentState = stateMachineContext.currentState;
    var stateMachine = currentState.stateMachine;

    if (widget.onFailedMessage != null) {
      _errorSubscription = stateMachine.failedMessages
          .listen((error) => widget.onFailedMessage!(currentState, error));
    }

    if (widget.onTransition != null) {
      var transitions = widget.transitionRootKey != null
          ? stateMachine.transitions.where((t) => !t.exitPath.contains(widget.transitionRootKey))
          : stateMachine.transitions;
      _transitionSubscription =
          transitions.listen((trans) => widget.onTransition!(currentState, trans));
    }
  }

  void _unsubscribe() {
    _transitionSubscription?.cancel();
    _errorSubscription?.cancel();
  }
}

class TreeStateMachineErrorDisplay extends StatefulWidget {
  const TreeStateMachineErrorDisplay({
    super.key,
    required this.errorBuilder,
    required this.child,
  });

  final Widget child;

  final Widget Function(BuildContext, FailedMessage, CurrentState) errorBuilder;

  @override
  State<TreeStateMachineErrorDisplay> createState() => _TreeStateMachineErrorDisplayState();
}

class _TreeStateMachineErrorDisplayState extends State<TreeStateMachineErrorDisplay> {
  FailedMessage? _failedMessage;
  CurrentState? _currentState;

  @override
  Widget build(BuildContext context) {
    return TreeStateMachineEvents(
      onFailedMessage: _onFailedMessage,
      child: _failedMessage != null
          ? widget.errorBuilder(context, _failedMessage!, _currentState!)
          : widget.child,
    );
  }

  void _onFailedMessage(CurrentState currentState, FailedMessage failedMessage) {
    setState(() {
      _failedMessage = failedMessage;
      _currentState = currentState;
    });
  }
}
