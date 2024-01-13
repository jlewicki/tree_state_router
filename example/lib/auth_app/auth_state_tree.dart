import 'dart:async';

import 'package:async/async.dart';
import 'package:tree_state_machine/delegate_builders.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router_examples/auth_app/models/models.dart';
import 'package:tree_state_router_examples/auth_app/services/auth_service.dart';

class AuthStates {
  static const authenticationRoot = StateKey('authenticationRoot');
  static const unauthenticated = StateKey('unauthenticated');
  static const login = DataStateKey<LoginData>('login');
  static const enterCredentials = StateKey('loginEntry');
  static const authenticating = StateKey('authenticating');
  static const registration = StateKey('registration');
  static const credentialsRegistration = StateKey('credentialsRegistration');
  static const demographicsRegistration = StateKey('demographicsRegistration');
  static const authenticated = DataStateKey<AuthenticatedData>('authenticated');
}

//
// Messages
//
class SubmitCredentials implements AuthenticationRequest {
  @override
  final String email;
  @override
  final String password;
  SubmitCredentials(this.email, this.password);
}

class SubmitDemographics {
  final String firstName;
  final String lastName;
  SubmitDemographics(this.firstName, this.lastName);
}

class AuthFuture {
  final Future<Result<AuthenticatedUser>> futureOr;
  AuthFuture(this.futureOr);
}

enum Messages { goToLogin, goToRegister, back, logout, submitRegistration }

//
// State Data
//
class RegisterData implements RegistrationRequest {
  @override
  String email = '';
  @override
  String password = '';
  @override
  String firstName = '';
  @override
  String lastName = '';
  bool isBusy = false;
  String errorMessage = '';
}

class LoginData implements AuthenticationRequest {
  @override
  String email = '';
  @override
  String password = '';
  bool rememberMe = false;
  String errorMessage = '';
}

class AuthenticatedData {
  final AuthenticatedUser user;
  AuthenticatedData(this.user);
}

StateTree authStateTree(AuthService authService) {
  AuthFuture login(LoginData data) {
    return AuthFuture(authService.authenticate(SubmitCredentials(
      data.email,
      data.password,
    )));
  }

  return StateTree.root(
    AuthStates.authenticationRoot,
    InitialChild(AuthStates.login),
    childStates: [
      DataState<LoginData>.composite(
        AuthStates.login,
        InitialData(() => LoginData()),
        InitialChild(AuthStates.enterCredentials),
        childStates: [
          State(
            AuthStates.enterCredentials,
            onMessage: (ctx) {
              if (ctx.message
                  case SubmitCredentials(email: var e, password: var p)) {
                ctx.data(AuthStates.login).update((current) => current
                  ..email = e
                  ..password = p);
                return ctx.goTo(AuthStates.authenticating);
              } else {
                return ctx.unhandled();
              }
            },
          ),
          // Model the 'logging in' status as a distinct state in the state
          // machine. This is an alternative design to modeling with a flag in
          // state data, as is done with 'registering' state.
          State(
            AuthStates.authenticating,
            onEnter: (ctx) => ctx.post(login(ctx.data(AuthStates.login).value)),
            onMessage: (ctx) async {
              if (ctx.message case AuthFuture(futureOr: var future)) {
                var result = await future;
                if (result.isValue) {
                  var user = result.asValue!.value;
                  return ctx.goTo(AuthStates.authenticated, payload: user);
                }
                ctx.data(AuthStates.login).update((current) =>
                    current..errorMessage = result.asError!.error.toString());
                return ctx.goTo(AuthStates.enterCredentials);
              }
              return ctx.unhandled();
            },
          ),
        ],
      ),
      DataState<AuthenticatedData>(
        AuthStates.authenticated,
        InitialData.run(fromPayload(
          (AuthenticatedUser p) => AuthenticatedData(p),
          orRedirectTo: AuthStates.login,
        )),
        onMessage: (ctx) => switch (ctx.message) {
          Messages.logout => ctx.goTo(AuthStates.login),
          _ => ctx.unhandled(),
        },
      ),
    ],
  );
}

GetInitialData<D?> fromPayload<D, P>(
  D? Function(P payload) initialData, {
  required StateKey orRedirectTo,
  Object? redirectPayload,
}) {
  return (transCtx) {
    if (transCtx.payload is P) {
      return initialData(transCtx.payload as P);
    }
    transCtx.redirectTo(AuthStates.login);
    return null;
  };
}
