enum UserRole { customer, salesOfficer }

class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.dni,
    required this.role,
  });

  final String id;
  final String fullName;
  final String email;
  final String dni;
  final UserRole role;
}
