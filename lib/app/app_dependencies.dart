import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/usecases/login_user.dart';
import '../features/auth/domain/usecases/register_user.dart';
import '../features/banking/data/repositories/banking_repository_impl.dart';
import '../features/banking/domain/usecases/create_customer_operation.dart';
import '../features/banking/domain/usecases/get_customer_banking_snapshot.dart';
import '../features/sales/data/repositories/sales_repository_impl.dart';
import '../features/sales/domain/usecases/get_sales_portfolio.dart';
import '../features/sales/domain/usecases/submit_credit_application.dart';
import '../shared/data/bank_data_source_strategy.dart';
import '../shared/data/bank_data_source.dart';

export '../shared/data/bank_data_source_strategy.dart'
    show LocalPostgresConnectionConfig;

class AppDependencies {
  const AppDependencies({
    required this.loginUser,
    required this.registerUser,
    required this.getCustomerBankingSnapshot,
    required this.createCustomerOperation,
    required this.getSalesPortfolio,
    required this.submitCreditApplication,
    required this.dataProvider,
    required BankDataSource dataSource,
  }) : _dataSource = dataSource;

  factory AppDependencies.mock() {
    return AppDependencies.fromStrategy(const MockDataSourceStrategy());
  }

  factory AppDependencies.supabase({
    required String url,
    required String anonKey,
  }) {
    return AppDependencies.fromStrategy(
      SupabaseDataSourceStrategy(url: url, anonKey: anonKey),
    );
  }

  factory AppDependencies.localPostgres({
    required LocalPostgresConnectionConfig config,
  }) {
    return AppDependencies.fromStrategy(
      LocalPostgresDataSourceStrategy(config: config),
    );
  }

  factory AppDependencies.coreMobileApi({required String baseUrl}) {
    return AppDependencies.fromStrategy(
      CoreMobileApiDataSourceStrategy(baseUrl: baseUrl),
    );
  }

  factory AppDependencies.fromStrategy(BankDataSourceStrategy strategy) {
    final dataSource = strategy.createDataSource();
    final authRepository = AuthRepositoryImpl(dataSource);
    final bankingRepository = BankingRepositoryImpl(dataSource);
    final salesRepository = SalesRepositoryImpl(dataSource);

    return AppDependencies(
      loginUser: LoginUser(authRepository),
      registerUser: RegisterUser(authRepository),
      getCustomerBankingSnapshot: GetCustomerBankingSnapshot(bankingRepository),
      createCustomerOperation: CreateCustomerOperation(bankingRepository),
      getSalesPortfolio: GetSalesPortfolio(salesRepository),
      submitCreditApplication: SubmitCreditApplication(salesRepository),
      dataProvider: strategy.provider,
      dataSource: dataSource,
    );
  }

  final LoginUser loginUser;
  final RegisterUser registerUser;
  final GetCustomerBankingSnapshot getCustomerBankingSnapshot;
  final CreateCustomerOperation createCustomerOperation;
  final GetSalesPortfolio getSalesPortfolio;
  final SubmitCreditApplication submitCreditApplication;
  final BankDataProvider dataProvider;
  final BankDataSource _dataSource;

  Future<void> createCustomerLoanRequest({
    required double amount,
    required int termMonths,
    required String purpose,
    required String businessType,
    required String businessName,
    required double income,
  }) {
    return _dataSource.createCustomerLoanRequest(
      amount: amount,
      termMonths: termMonths,
      purpose: purpose,
      businessType: businessType,
      businessName: businessName,
      income: income,
    );
  }

  Future<void> completeAssignedApplication({
    required String applicationId,
    required double income,
    required double expenses,
    required double assets,
    required double? latitude,
    required double? longitude,
  }) {
    return _dataSource.completeAssignedApplication(
      applicationId: applicationId,
      income: income,
      expenses: expenses,
      assets: assets,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
