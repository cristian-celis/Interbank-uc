import 'dart:io';

import 'package:interbank_uc/features/auth/domain/entities/auth_requests.dart';
import 'package:interbank_uc/features/sales/domain/entities/sales_portfolio.dart';
import 'package:interbank_uc/shared/data/bank_data_source_strategy.dart';

Future<void> main(List<String> args) async {
  final config = LocalPostgresConnectionConfig(
    host: Platform.environment['PG_HOST'] ?? 'localhost',
    port: int.tryParse(Platform.environment['PG_PORT'] ?? '') ?? 5432,
    database: Platform.environment['PG_DATABASE'] ?? 'bd_appmovil_fventas',
    username: Platform.environment['PG_USER'] ?? 'postgres',
    password: Platform.environment['PG_PASSWORD'] ?? 'postgres',
  );

  final dataSource = LocalPostgresDataSourceStrategy(
    config: config,
  ).createDataSource();

  final customer = await dataSource.login(
    const LoginRequest(email: 'rosa.condori@gmail.com', password: '123456'),
  );
  stdout.writeln(
    'customer_login=${customer.fullName} role=${customer.role.name}',
  );

  final customerSnapshot = await dataSource.getCustomerSnapshot(customer.id);
  stdout.writeln(
    'customer_snapshot=${customerSnapshot.customerName} '
    'accounts=${customerSnapshot.savingsAccounts.length} '
    'movements=${customerSnapshot.movements.length} '
    'credits=${customerSnapshot.credits.length}',
  );

  final officer = await dataSource.login(
    const LoginRequest(email: 'jessica.quispe@fieldiq.pe', password: '123456'),
  );
  stdout.writeln('sales_login=${officer.fullName} role=${officer.role.name}');

  final portfolio = await dataSource.getSalesPortfolio(officer.id);
  stdout.writeln(
    'portfolio=${portfolio.officerName} visits=${portfolio.dailyVisits.length} '
    'applications=${portfolio.activeApplications.length}',
  );

  if (args.contains('--write')) {
    final application = await dataSource.submitCreditApplication(
      CreditApplicationDraft(
        officerId: officer.id,
        customerName: 'Smoke Test Flutter',
        dni: '12345678',
        phone: '987654321',
        amount: 1000,
        businessActivity: 'Validacion tecnica',
        offlineCaptured: true,
        documents: const [
          DocumentCapture(
            type: 'DNI frontal',
            fileName: 'smoke_dni.jpg',
            captured: true,
          ),
        ],
      ),
    );
    stdout.writeln(
      'inserted=${application.id} status=${application.status.name} '
      'transmitted=${application.transmitted}',
    );
  } else {
    stdout.writeln(
      'write=skipped (run with --write to insert a ficha_campo smoke row)',
    );
  }
}
