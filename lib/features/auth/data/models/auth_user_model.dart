import '../../domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.dni,
    required super.role,
  });

  factory AuthUserModel.fromMap(Map<String, Object?> map) {
    return AuthUserModel(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      email: map['email'] as String,
      dni: map['dni'] as String,
      role: _roleFromString(map['role'] as String),
    );
  }

  static UserRole _roleFromString(String value) {
    return value == 'salesOfficer' ? UserRole.salesOfficer : UserRole.customer;
  }
}
