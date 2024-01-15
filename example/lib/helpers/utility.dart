import 'package:tree_state_machine/tree_state_machine.dart';

GetInitialData<D?> fromPayload<D, P>(
  D? Function(P payload) initialData, {
  required StateKey orRedirectTo,
  Object? redirectPayload,
}) {
  return (transCtx) {
    if (transCtx.payload is P) {
      return initialData(transCtx.payload as P);
    }
    transCtx.redirectTo(orRedirectTo);
    return null;
  };
}

GetInitialData<D?> fromPayload2<D, P1, P2>(
  D? Function(P1 payload) initialData1,
  D? Function(P2 payload) initialData2, {
  required StateKey orRedirectTo,
  Object? redirectPayload,
}) {
  return (transCtx) {
    if (transCtx.payload is P1) {
      return initialData1(transCtx.payload as P1);
    } else if (transCtx.payload is P2) {
      return initialData2(transCtx.payload as P2);
    }
    transCtx.redirectTo(orRedirectTo);
    return null;
  };
}
