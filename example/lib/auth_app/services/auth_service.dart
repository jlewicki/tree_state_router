import 'package:async/async.dart';
import 'package:tree_state_router_examples/auth_app/models/models.dart';

abstract class AuthService {
  Future<Result<AuthenticatedUser>> authenticate(AuthenticationRequest request);
  Future<Result<AuthenticatedUser>> register(RegistrationRequest request);
}

class AppAuthService implements AuthService {
  @override
  Future<Result<AuthenticatedUser>> authenticate(
    AuthenticationRequest request,
  ) async {
    // Emulate network latency
    await Future.delayed(const Duration(seconds: 2));

    return request.email.toLowerCase() == 'fail'
        ? Result.error('Unrecognized email address or password.')
        : Result.value(AuthenticatedUser('Joey', 'Tribbiani', request.email));
  }

  @override
  Future<Result<AuthenticatedUser>> register(
    RegistrationRequest request,
  ) async {
    // Emulate network latency
    await Future.delayed(const Duration(seconds: 3));

    return Result.value(AuthenticatedUser('Joey', 'Tribbiani', request.email));
  }
}
