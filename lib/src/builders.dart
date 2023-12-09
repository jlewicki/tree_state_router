import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_machine/async.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/src/provider.dart';

/// A function that constructs widget that visualizes an active tree state in a state machine.
///
/// The function is provided the [currentState] of the tree state machine.
typedef TreeStateWidgetBuilder = Widget Function(
  BuildContext context,
  CurrentState currentState,
);

/// A function that constructs widget that visualizes a tree state, using data type of [D] from
/// an active data tree state.
///
/// The function is provided the current [stateData] for the state, and the [currentState] of the
/// tree state machine.
typedef DataTreeStateWidgetBuilder<D> = Widget Function(
  BuildContext context,
  CurrentState currentState,
  D stateData,
);

/// A function that constructs widget that visualizes a tree state, using data types of [D1] and
/// [D2] from active data tree states.
///
/// The function is provided the current [stateData1] and [stateData2] for the data states, along
/// with the [currentState] of the tree state machine.
typedef DataTreeStateWidgetBuilder2<D1, D2> = Widget Function(
  BuildContext context,
  CurrentState currentState,
  D1 stateData1,
  D2 stateData2,
);

/// A function that constructs widget that visualizes a tree state, using data types of [D1], [D2],
/// and [D3] from active data tree states.
///
/// The function is provided the current [stateData1], [stateData2], and [stateData3] for the data
/// states, along with the [currentState] of the tree state machine.
typedef DataTreeStateWidgetBuilder3<D1, D2, D3> = Widget Function(
  BuildContext context,
  CurrentState currentState,
  D1 stateData1,
  D2 stateData2,
  D3 stateData3,
);

/// Base class for widgets that display a data tree state.
abstract class BaseDataTreeStateBuilder extends StatefulWidget {
  const BaseDataTreeStateBuilder(
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
  DataTreeStateBuilderState createState() => DataTreeStateBuilderState();
}

/// A widget that builds itself, using tree state data, when a specific tree state is an
/// active state in a [TreeStateMachine].
///
/// The tree state for which this widget builds itself is identified by [stateKey]. If this state
/// is an active state in the state machine, the [builder] function is called to obtain the widget
/// to display.
///
/// The type parameter [D] indicates the type of state data that is provided to the [builder]
/// function. This data is obtained from an active data state, which may be the state identified by
/// [stateKey], or one of its ancestor data states.
class DataTreeStateBuilder<D> extends BaseDataTreeStateBuilder {
  DataTreeStateBuilder({
    Key? key,
    required StateKey stateKey,
    required DataTreeStateWidgetBuilder<D> builder,
    DataStateKey<D>? dataStateKey,
  }) : super(
            key,
            stateKey,
            [StateDataResolver<D>(dataStateKey ?? (stateKey is DataStateKey<D> ? stateKey : null))],
            (context, dataList, currentState) => builder(
                  context,
                  currentState,
                  dataList.getAs<D>(0),
                ));
}

/// A widget that builds itself, using tree state data, itself when a specific tree state is an
/// active state in a [TreeStateMachine].
///
/// The tree state for which this widget builds itself is identified by [stateKey]. If this state
/// is an active state in the state machine, the [builder] function is called to obtain the widget
/// to display.
///
/// The type parameters [D1] and [D2] indicate the types of state data that is provided to the [builder]
/// function. These values are obtained from active data states, one which may be the state
/// identified by [stateKey], or one of its ancestor data states.
class DataTreeStateBuilder2<D1, D2> extends BaseDataTreeStateBuilder {
  DataTreeStateBuilder2({
    Key? key,
    required StateKey stateKey,
    required DataTreeStateWidgetBuilder2<D1, D2> builder,
    DataStateKey<D1>? dataStateKey1,
    DataStateKey<D2>? dataStateKey2,
  }) : super(
            key,
            stateKey,
            [
              StateDataResolver<D1>(dataStateKey1),
              StateDataResolver<D2>(dataStateKey2),
            ],
            (context, dataList, currentState) => builder(
                  context,
                  currentState,
                  dataList.getAs<D1>(0),
                  dataList.getAs<D2>(1),
                ));
}

/// A widget that builds itself, using tree state data, itself when a specific tree state is an
/// active state in a [TreeStateMachine].
///
/// The tree state for which this widget builds itself is identified by [stateKey]. If this state
/// is an active state in the state machine, the [builder] function is called to obtain the widget
/// to display.
///
/// The type parameters [D1], [D2] and [D3] indicate the types of state data that is provided to the
/// [builder] function. These values are obtained from active data states, one which may be the state
/// identified by [stateKey], or one of its ancestor data states.
class DataTreeStateBuilder3<D1, D2, D3> extends BaseDataTreeStateBuilder {
  DataTreeStateBuilder3({
    Key? key,
    required StateKey stateKey,
    required DataTreeStateWidgetBuilder3<D1, D2, D3> builder,
    DataStateKey<D1>? dataStateKey1,
    DataStateKey<D2>? dataStateKey2,
    DataStateKey<D3>? dataStateKey3,
  }) : super(
            key,
            stateKey,
            [
              StateDataResolver<D1>(dataStateKey1),
              StateDataResolver<D2>(dataStateKey2),
              StateDataResolver<D3>(dataStateKey3),
            ],
            (context, dataList, currentState) => builder(
                  context,
                  currentState,
                  dataList.getAs<D1>(0),
                  dataList.getAs<D2>(1),
                  dataList.getAs<D3>(2),
                ));
}

class DataTreeStateBuilderState extends State<BaseDataTreeStateBuilder> {
  StreamSubscription? _combinedDataSubscription;
  StreamSubscription? _activeDescendantSubscription;
  List<dynamic>? _stateDataList;
  AsyncError? _error;
  late final Logger _log = Logger('$runtimeType.${widget.stateKey}');

  @override
  void didUpdateWidget(BaseDataTreeStateBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stateKey != oldWidget.stateKey ||
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
        : widget._widgetBuilder(context, _stateDataList!, stateMachineContext!.currentState);
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
          assert(stream != null, 'Data stream for state ${resolve.stateKey} could not be resolved');
          assert(stream!.hasValue, 'A resolved data stream should have a value');
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
      onDone: () => {
        _log.finer(
            'CombineLatestDone for data streams ${widget._stateDataResolvers.map((e) => e.stateKey.toString()).join(', ')}')
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

typedef _TreeStateDataListWidgetBuilder = Widget Function(
  BuildContext context,
  List stateDataList,
  CurrentState currentState,
);

extension _ListExtensions on List<dynamic> {
  T getAs<T>(int index) {
    return const _TypeLiteral<void>().type == T ? null as T : this[index] as T;
  }
}

class _TypeLiteral<T> {
  const _TypeLiteral();
  Type get type => T;
}

// Helper class to re-use resolver instances so that that we don't do extraneous work in
// _TreeStateBuilderState.didUpdateWidget
class StateDataResolver<D> {
  final DataStateKey<D>? stateKey;
  static final _resolversByType = <String, StateDataResolver>{};
  StateDataResolver._(this.stateKey);

  factory StateDataResolver([DataStateKey<D>? stateKey]) {
    var key = '$stateKey-$D';
    var resolver = _resolversByType[key];
    if (resolver == null) {
      resolver = StateDataResolver<D>._(stateKey);
      _resolversByType[key] = resolver;
    }
    return resolver as StateDataResolver<D>;
  }

  ValueStream? call(CurrentState currentState) => currentState.dataStream<D>(stateKey);
}
