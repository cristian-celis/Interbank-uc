import '../entities/sales_portfolio.dart';

abstract class SalesRepository {
  Future<SalesPortfolioSnapshot> getPortfolio(String officerId);
  Future<CreditApplication> submitApplication(CreditApplicationDraft draft);
}
