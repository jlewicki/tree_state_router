class AuthenticatedUser {
  AuthenticatedUser(this.firstName, this.lastName, this.email);

  final String firstName;
  final String lastName;
  final String email;

  String get name => '$firstName $lastName';

  @override
  int get hashCode => Object.hash(firstName, lastName, email);

  @override
  bool operator ==(Object other) =>
      other is AuthenticatedUser &&
      firstName == other.firstName &&
      lastName == other.lastName &&
      email == other.email;
}

class RegistrationRequest {
  final String email = '';
  final String password = '';
  final String firstName = '';
  final String lastName = '';
}

class AuthenticationRequest {
  final String email = '';
  final String password = '';
}
