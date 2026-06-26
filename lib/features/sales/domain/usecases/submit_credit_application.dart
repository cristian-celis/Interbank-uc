import '../entities/sales_portfolio.dart';
import '../repositories/sales_repository.dart';

class SubmitCreditApplication {
  const SubmitCreditApplication(this._repository);

  final SalesRepository _repository;

  Future<CreditApplication> call(CreditApplicationDraft draft) {
    return _repository.submitApplication(draft);
  }
}
