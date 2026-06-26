import '../../features/auth/domain/entities/auth_requests.dart';
import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/banking/domain/entities/banking_snapshot.dart';
import '../../features/sales/domain/entities/sales_portfolio.dart';

abstract class BankDataSource {
  Future<AuthUser> login(LoginRequest request);
  Future<AuthUser> register(RegisterRequest request);
  Future<CustomerBankingSnapshot> getCustomerSnapshot(String customerId);
  Future<void> createCustomerOperation({
    required String originAccount,
    required String? destinationAccount,
    required String type,
    required double amount,
  });
  Future<void> createCustomerLoanRequest({
    required double amount,
    required int termMonths,
    required String purpose,
    required String businessType,
    required String businessName,
    required double income,
  });
  Future<SalesPortfolioSnapshot> getSalesPortfolio(String officerId);
  Future<void> completeAssignedApplication({
    required String applicationId,
    required double income,
    required double expenses,
    required double assets,
    required double? latitude,
    required double? longitude,
  });
  Future<CreditApplication> submitCreditApplication(
    CreditApplicationDraft draft,
  );
}
