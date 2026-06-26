import '../entities/banking_snapshot.dart';

abstract class BankingRepository {
  Future<CustomerBankingSnapshot> getCustomerSnapshot(String customerId);
  Future<void> createCustomerOperation({
    required String originAccount,
    required String? destinationAccount,
    required String type,
    required double amount,
  });
}
