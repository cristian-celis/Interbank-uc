import '../entities/auth_requests.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class LoginUser {
  const LoginUser(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call(LoginRequest request) {
    return _repository.login(request);
  }
}
