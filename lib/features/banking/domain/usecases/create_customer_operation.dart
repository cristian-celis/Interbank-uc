import '../repositories/banking_repository.dart';

class CreateCustomerOperation {
  const CreateCustomerOperation(this._repository);

  final BankingRepository _repository;

  Future<void> call({
    required String originAccount,
    required String? destinationAccount,
    required String type,
    required double amount,
  }) {
    return _repository.createCustomerOperation(
      originAccount: originAccount,
      destinationAccount: destinationAccount,
      type: type,
      amount: amount,
    );
  }
}
