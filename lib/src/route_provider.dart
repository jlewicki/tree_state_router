import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/router_config.dart';
import 'package:tree_state_router/tree_state_router.dart';

class TreeStateRouteInformationProvider extends RouteInformationProvider
    with WidgetsBindingObserver, ChangeNotifier {
  /// Constructs a [TreeStateRouteInformationProvider] that will provide routing information
  /// based on the active states in [stateMachine]
  TreeStateRouteInformationProvider(
    List<StateRouteConfigProvider> routes,
    this._stateMachine,
    this._deepLinkRouteTable,
  ) {
    // As transitions occur, look for states that are entered whose routes are deep-linkable, and
    // report those routes to the routing engine
    _transitionsSubscription = _stateMachine.transitions
        .map(_deepLinkRouteTable.transitionRouteInformation)
        .where((r) => r != null)
        .cast<RouteInformation>()
        .listen(_onTransitionRouteInformation);
  }

  final TreeStateMachine _stateMachine;
  final DeepLinkRouteTable _deepLinkRouteTable;
  late RouteInformation _value = _initialRouteInformation(_stateMachine);
  StreamSubscription? _transitionsSubscription;

  @override
  RouteInformation get value => _value;

  static WidgetsBinding get _binding => WidgetsBinding.instance;

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    final bool replace;
    switch (type) {
      // case RouteInformationReportingType.none:
      //   if (_valueInEngine.location == routeInformation.location &&
      //       const DeepCollectionEquality()
      //           .equals(_valueInEngine.state, routeInformation.state)) {
      //     return;
      //   }
      //   replace = _valueInEngine == _kEmptyRouteInformation;
      //   break;
      case RouteInformationReportingType.neglect:
        replace = true;
        break;
      case RouteInformationReportingType.navigate:
        replace = false;
        break;
      default:
        replace = true;
    }
    SystemNavigator.selectMultiEntryHistory();
    SystemNavigator.routeInformationUpdated(
      uri: routeInformation.uri,
      state: routeInformation.state,
      replace: replace,
    );

    _value = routeInformation;
  }

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners) {
      _binding.addObserver(this);
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _binding.removeObserver(this);
    }
  }

  @override
  void dispose() {
    if (hasListeners) {
      _binding.removeObserver(this);
    }
    _transitionsSubscription?.cancel();
    super.dispose();
  }

  RouteInformation _initialRouteInformation(TreeStateMachine stateMachine) {
    if (stateMachine.lifecycle.value == LifecycleState.started) {}

    return RouteInformation(
      uri: Uri.parse(
        WidgetsBinding.instance.platformDispatcher.defaultRouteName,
      ),
    );
  }

  void _onTransitionRouteInformation(RouteInformation routeInformation) {
    _value = routeInformation;
    notifyListeners();
  }
}
