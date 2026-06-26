import '../../../../shared/data/bank_data_source.dart';
import '../../domain/entities/auth_requests.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource);

  final BankDataSource _dataSource;

  @override
  Future<AuthUser> login(LoginRequest request) {
    return _dataSource.login(request);
  }

  @override
  Future<AuthUser> register(RegisterRequest request) {
    return _dataSource.register(request);
  }
}
