import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum SystemNavigatorHistoryMode {
  singleEntry,
  multiEntry,
}

/// A [RouteInformationProvider] providing some degree of control over whether single or multi-entry
/// history is enabled for [SystemNavigator].
///
/// This implementation is based almost exactly on [PlatformRouteInformationProvider], with some
/// tiny adjustments to [routerReportsNewRouteInformation]. Unfortunately it does not appear
/// possible to achieve this just by extending [PlatformRouteInformationProvider], so the entire
/// implementation was duplicated.
class TreeStateRouteInformationProvider extends RouteInformationProvider
    with WidgetsBindingObserver, ChangeNotifier {
  /// Create a platform route information provider.
  ///
  /// Use the [initialRouteInformation] to set the default route information for this
  /// provider.
  TreeStateRouteInformationProvider({
    required RouteInformation initialRouteInformation,
    required this.historyMode,
  }) : _value = initialRouteInformation {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  final SystemNavigatorHistoryMode historyMode;

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    final bool replace = type == RouteInformationReportingType.neglect ||
        (type == RouteInformationReportingType.none &&
            _equals(_valueInEngine.uri, routeInformation.uri));

    // Even if historyMode == SystemNavigatorHistoryMode.singleEntry, apparently we want to
    // call selectMultiEntryHistory() (even though selectEntryEntryHistory() would be more intuitive)
    // Oherwise, in Chrome at least, we still end up with history entries and an active back button
    // Seems weird. But the combination of
    //  - selectMultiEntryHistory() and
    //  - routeInformationUpdated(replace: true)
    // appears to give the desired effect (updated URL but no history entries)
    SystemNavigator.selectMultiEntryHistory();
    SystemNavigator.routeInformationUpdated(
      uri: routeInformation.uri,
      state: routeInformation.state,
      replace: historyMode == SystemNavigatorHistoryMode.singleEntry
          ? true
          : replace,
    );

    _value = routeInformation;
    _valueInEngine = routeInformation;
  }

  @override
  RouteInformation get value => _value;
  RouteInformation _value;

  RouteInformation _valueInEngine = RouteInformation(
      uri: Uri.parse(
          WidgetsBinding.instance.platformDispatcher.defaultRouteName));

  void _platformReportsNewRouteInformation(RouteInformation routeInformation) {
    if (_value == routeInformation) {
      return;
    }
    _value = routeInformation;
    _valueInEngine = routeInformation;
    notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners) {
      WidgetsBinding.instance.addObserver(this);
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      WidgetsBinding.instance.removeObserver(this);
    }
  }

  @override
  void dispose() {
    if (hasListeners) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  Future<bool> didPushRouteInformation(
      RouteInformation routeInformation) async {
    assert(hasListeners);
    _platformReportsNewRouteInformation(routeInformation);
    return true;
  }

  static bool _equals(Uri a, Uri b) {
    return a.path == b.path &&
        a.fragment == b.fragment &&
        const DeepCollectionEquality.unordered()
            .equals(a.queryParametersAll, b.queryParametersAll);
  }
}
