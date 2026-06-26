class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
    this.dni,
  });

  final String email;
  final String password;
  final String? dni;
}

class RegisterRequest {
  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.dni,
    required this.password,
  });

  final String fullName;
  final String email;
  final String dni;
  final String password;
}
