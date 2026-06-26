import '../entities/sales_portfolio.dart';
import '../repositories/sales_repository.dart';

class GetSalesPortfolio {
  const GetSalesPortfolio(this._repository);

  final SalesRepository _repository;

  Future<SalesPortfolioSnapshot> call(String officerId) {
    return _repository.getPortfolio(officerId);
  }
}
