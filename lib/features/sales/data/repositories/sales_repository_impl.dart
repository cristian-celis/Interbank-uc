import '../../../../shared/data/bank_data_source.dart';
import '../../domain/entities/sales_portfolio.dart';
import '../../domain/repositories/sales_repository.dart';

class SalesRepositoryImpl implements SalesRepository {
  const SalesRepositoryImpl(this._dataSource);

  final BankDataSource _dataSource;

  @override
  Future<SalesPortfolioSnapshot> getPortfolio(String officerId) {
    return _dataSource.getSalesPortfolio(officerId);
  }

  @override
  Future<CreditApplication> submitApplication(CreditApplicationDraft draft) {
    return _dataSource.submitCreditApplication(draft);
  }
}
