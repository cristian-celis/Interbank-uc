import '../entities/auth_requests.dart';
import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser> login(LoginRequest request);
  Future<AuthUser> register(RegisterRequest request);
}
