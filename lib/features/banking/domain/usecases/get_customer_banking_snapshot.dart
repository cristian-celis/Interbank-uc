import '../entities/banking_snapshot.dart';
import '../repositories/banking_repository.dart';

class GetCustomerBankingSnapshot {
  const GetCustomerBankingSnapshot(this._repository);

  final BankingRepository _repository;

  Future<CustomerBankingSnapshot> call(String customerId) {
    return _repository.getCustomerSnapshot(customerId);
  }
}
