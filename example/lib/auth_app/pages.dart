import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:tree_state_machine/tree_state_machine.dart';
import 'package:tree_state_router/tree_state_router.dart';
import 'package:tree_state_router_examples/auth_app/auth_state_tree.dart';
import 'package:tree_state_router_examples/auth_app/helpers.dart';

final _log = Logger('pages');
final formKey = GlobalKey<FormState>();

Widget loginPage(
  BuildContext buildCtx,
  StateRoutingContext routeCtx,
  LoginData data,
) {
  _log.info('building login page');

  var currentState = routeCtx.currentState;
  bool isAuthenticating = currentState.isInState(AuthStates.authenticating);
  String? email = data.email;
  String? password = data.password;

  String? validateEmail(String? value) {
    return (email = value)?.isEmpty ?? true
        ? 'Please enter an email address.'
        : null;
  }

  String? validatePassword(String? value) {
    return (password = value)?.isEmpty ?? true
        ? 'Please enter a password'
        : null;
  }

  String errorMessage(LoginData data) {
    return isAuthenticating ? '' : data.errorMessage;
  }

  void submit(CurrentState currentState) {
    if (formKey.currentState?.validate() ?? false) {
      currentState.post(SubmitCredentials(email!, password!));
    }
  }

  return Form(
    key: formKey,
    child: Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Spacer(),
          AuthFormFieldGroup(
            title: 'What is your name?',
            formFields: [
              AuthFormField(
                'firstName',
                'Email Address',
                data.email,
                validator: validateEmail,
                isEnabled: !isAuthenticating,
              ),
              AuthFormField(
                'lastName',
                'Password',
                data.password,
                validator: validatePassword,
                isEnabled: !isAuthenticating,
              )
            ],
          ),
          Flexible(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 200,
                    child: FilledButton(
                      onPressed:
                          isAuthenticating ? null : () => submit(currentState),
                      child: Text(
                          isAuthenticating ? 'Authenticating...' : 'Log In'),
                    ),
                  ),
                  Center(
                    child: Text(
                      errorMessage(data),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget authenticatedPage(
  BuildContext buildCtx,
  StateRoutingContext routeCtx,
  AuthenticatedData data,
) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "${data.user.firstName} ${data.user.lastName}, how you doin'?",
          style: Theme.of(buildCtx).textTheme.headlineMedium,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: FilledButton(
              onPressed: () => routeCtx.currentState.post(Messages.logout),
              child: const Text('Logout')),
        )
      ],
    ),
  );
}
