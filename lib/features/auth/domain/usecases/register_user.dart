import '../entities/auth_requests.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class RegisterUser {
  const RegisterUser(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call(RegisterRequest request) {
    return _repository.register(request);
  }
}
