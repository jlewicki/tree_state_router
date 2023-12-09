import 'package:tree_state_machine/tree_state_machine.dart';

class RoutingMessage {
  RoutingMessage(this.targetState, [this.payload]);
  final StateKey targetState;
  final Object? payload;
}
