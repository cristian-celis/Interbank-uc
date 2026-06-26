import '../../../../shared/data/bank_data_source.dart';
import '../../domain/entities/banking_snapshot.dart';
import '../../domain/repositories/banking_repository.dart';

class BankingRepositoryImpl implements BankingRepository {
  const BankingRepositoryImpl(this._dataSource);

  final BankDataSource _dataSource;

  @override
  Future<CustomerBankingSnapshot> getCustomerSnapshot(String customerId) {
    return _dataSource.getCustomerSnapshot(customerId);
  }

  @override
  Future<void> createCustomerOperation({
    required String originAccount,
    required String? destinationAccount,
    required String type,
    required double amount,
  }) {
    return _dataSource.createCustomerOperation(
      originAccount: originAccount,
      destinationAccount: destinationAccount,
      type: type,
      amount: amount,
    );
  }
}
