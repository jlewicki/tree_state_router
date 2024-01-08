import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_machine/async.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';

class DataStateBuilder extends StatefulWidget {
  const DataStateBuilder(
    Key? key,
    this.stateKey,
    this._stateDataResolvers,
    this._widgetBuilder,
  ) : super(key: key);

  /// Identifies the tree state for which a widget is being displayed.
  final StateKey stateKey;

  final List<StateDataResolver> _stateDataResolvers;
  final _TreeStateDataListWidgetBuilder _widgetBuilder;

  @override
  DataStateBuilderState createState() => DataStateBuilderState();
}

class DataStateBuilderState extends State<DataStateBuilder> {
  StreamSubscription? _combinedDataSubscription;
  StreamSubscription? _activeDescendantSubscription;
  List<dynamic>? _stateDataList;
  AsyncError? _error;
  late final Logger _log = Logger('$runtimeType.${widget.stateKey}');

  @override
  void didUpdateWidget(DataStateBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_combinedDataSubscription == null ||
        widget.stateKey != oldWidget.stateKey ||
        !_areResolversEqual(oldWidget._stateDataResolvers)) {
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
  Widget build(BuildContext context) {
    var stateMachineContext = TreeStateMachineProvider.of(context);
    assert(stateMachineContext != null);
    assert(_stateDataList != null);
    return _error != null
        ? ErrorWidget(_error!)
        : widget._widgetBuilder(
            context, _stateDataList!, stateMachineContext!.currentState);
  }

  void _subscribe() {
    var stateMachineContext = TreeStateMachineProvider.of(context);
    assert(stateMachineContext != null);

    var currentState = stateMachineContext!.currentState;
    if (!currentState.isInState(widget.stateKey)) return;

    var initialValues = <dynamic>[];
    var dataStreams = widget._stateDataResolvers
        .map((resolve) {
          var stream = resolve(currentState);
          assert(stream != null,
              'Data stream for state ${resolve.stateKey} could not be resolved');
          assert(
              stream!.hasValue, 'A resolved data stream should have a value');
          if (stream != null) initialValues.add(stream.value);
          return stream;
        })
        .where((stream) {
          return stream != null;
        })
        .cast<ValueStream>()
        .toList();

    var combinedDataStream = StreamCombineLatest(dataStreams);
    _stateDataList = initialValues.toList();
    _combinedDataSubscription = combinedDataStream.listen(
      (stateDataValues) {
        setState(() => _stateDataList = stateDataValues);
      },
      onError: (err, stackTrace) {
        setState(() => _error = AsyncError(err, stackTrace));
      },
      onDone: () {
        _log.finer('CombineLatestDone for data streams '
            '${widget._stateDataResolvers.map(
                  (e) => e.stateKey.toString(),
                ).join(', ')}');
        // If a data state is re-entered, the its value stream will
        // be ended, but the current state of the state machine will not change.
        // So set this subscription to null so we can tell that we will need to
        // re-subscribe to pick up the latest value.
        _combinedDataSubscription = null;
      },
    );
  }

  void _unsubscribe() {
    _combinedDataSubscription?.cancel();
    _activeDescendantSubscription?.cancel();
  }

  bool _areResolversEqual(List<StateDataResolver> otherResolvers) {
    var resolvers = widget._stateDataResolvers;
    if (otherResolvers.length == widget._stateDataResolvers.length) {
      for (var i = 0; i < otherResolvers.length; i++) {
        if (otherResolvers[i] != resolvers[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }
}

class StateDataResolver<D> {
  final DataStateKey<D> stateKey;
  static final _resolversByType = <String, StateDataResolver>{};
  StateDataResolver._(this.stateKey);

  factory StateDataResolver(DataStateKey<D> stateKey) {
    var key = '$stateKey-$D';
    var resolver = _resolversByType[key];
    if (resolver == null) {
      resolver = StateDataResolver<D>._(stateKey);
      _resolversByType[key] = resolver;
    }
    return resolver as StateDataResolver<D>;
  }

  ValueStream? call(CurrentState currentState) =>
      currentState.dataStream<D>(stateKey);
}

typedef _TreeStateDataListWidgetBuilder = Widget Function(
  BuildContext context,
  List stateDataList,
  CurrentState currentState,
);

extension ListExtensions on List<dynamic> {
  T getAs<T>(int index) {
    return const _TypeLiteral<void>().type == T ? null as T : this[index] as T;
  }
}

class _TypeLiteral<T> {
  const _TypeLiteral();
  Type get type => T;
}

StateRouteConfig createDataStateRouteConfig1<D1>(
  StateKey stateKey,
  DataStateRouteBuilder<D1>? routeBuilder,
  DataStateRoutePageBuilder<D1>? routePageBuilder,
  List<StateDataResolver> resolvers,
  bool isPopup,
  RoutePathConfig? path,
  List<StateRouteConfig> childRoutes,
) {
  DataStateBuilder createDataStateBuilder1(
    StateRoutingContext stateContext,
    DataStateRouteBuilder<D1> buildPageContent,
  ) {
    return DataStateBuilder(
      ValueKey(stateKey),
      stateKey,
      resolvers,
      (context, dataList, currentState) => buildPageContent(
        context,
        stateContext,
        dataList.getAs<D1>(0),
      ),
    );
  }

  return StateRouteConfig(
    stateKey,
    routeBuilder: routeBuilder != null
        ? (context, stateContext) =>
            createDataStateBuilder1(stateContext, routeBuilder)
        : null,
    routePageBuilder: routePageBuilder != null
        ? (context, wrapContent) => routePageBuilder.call(
              context,
              (buildPageContent) => wrapContent((context, stateContext) =>
                  createDataStateBuilder1(stateContext, buildPageContent)),
            )
        : null,
    isPopup: isPopup,
    dependencies: resolvers.map((e) => e.stateKey).toList(),
    path: path,
    childRoutes: childRoutes,
  );
}

StateRouteConfig createDataStateRouteConfig2<D1, D2>(
  StateKey stateKey,
  DataStateRouteBuilder2<D1, D2>? routeBuilder,
  DataStateRoutePageBuilder2<D1, D2>? routePageBuilder,
  List<StateDataResolver> resolvers,
  bool isPopup,
) {
  DataStateBuilder createDataStateBuilder2(
    StateRoutingContext stateContext,
    DataStateRouteBuilder2<D1, D2> buildPageContent,
  ) {
    return DataStateBuilder(
      ValueKey(stateKey),
      stateKey,
      resolvers,
      (context, dataList, currentState) => buildPageContent(
        context,
        stateContext,
        dataList.getAs<D1>(0),
        dataList.getAs<D2>(1),
      ),
    );
  }

  return StateRouteConfig(
    stateKey,
    routeBuilder: routeBuilder != null
        ? (context, stateContext) =>
            createDataStateBuilder2(stateContext, routeBuilder)
        : null,
    routePageBuilder: routePageBuilder != null
        ? (context, wrapContent) => routePageBuilder.call(
              context,
              (buildPageContent) => wrapContent((context, stateContext) =>
                  createDataStateBuilder2(stateContext, buildPageContent)),
            )
        : null,
    isPopup: isPopup,
    dependencies: resolvers.map((e) => e.stateKey).toList(),
  );
}

StateRouteConfig createDataStateRouteConfig3<D1, D2, D3>(
  StateKey stateKey,
  DataStateRouteBuilder3<D1, D2, D3>? routeBuilder,
  DataStateRoutePageBuilder3<D1, D2, D3>? routePageBuilder,
  List<StateDataResolver> resolvers,
  bool isPopup,
) {
  DataStateBuilder createDataStateBuilder3(
    StateRoutingContext stateContext,
    DataStateRouteBuilder3<D1, D2, D3> buildPageContent,
  ) {
    return DataStateBuilder(
      ValueKey(stateKey),
      stateKey,
      resolvers,
      (context, dataList, currentState) => buildPageContent(
        context,
        stateContext,
        dataList.getAs<D1>(0),
        dataList.getAs<D2>(1),
        dataList.getAs<D3>(2),
      ),
    );
  }

  return StateRouteConfig(
    stateKey,
    routeBuilder: routeBuilder != null
        ? (context, stateContext) =>
            createDataStateBuilder3(stateContext, routeBuilder)
        : null,
    routePageBuilder: routePageBuilder != null
        ? (context, wrapContent) => routePageBuilder.call(
              context,
              (buildPageContent) => wrapContent((context, stateContext) =>
                  createDataStateBuilder3(stateContext, buildPageContent)),
            )
        : null,
    isPopup: isPopup,
    dependencies: resolvers.map((e) => e.stateKey).toList(),
  );
}
