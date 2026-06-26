import 'package:flutter_test/flutter_test.dart';
import 'package:interbank_uc/app/app_dependencies.dart';
import 'package:interbank_uc/app/customer_banking_app.dart';
import 'package:interbank_uc/app/sales_force_app.dart';

void main() {
  testWidgets('muestra login de la app de clientes', (tester) async {
    await tester.pumpWidget(
      CustomerBankingApp(dependencies: AppDependencies.mock()),
    );

    expect(find.text('Interbank UC'), findsOneWidget);
    expect(find.text('App Clientes'), findsOneWidget);
    expect(find.text('Bienvenido'), findsOneWidget);
    expect(
      find.text('Ingresa para consultar tus productos de banca movil.'),
      findsOneWidget,
    );
    expect(find.text('rosa.condori@gmail.com'), findsOneWidget);
    expect(find.text('Crear una cuenta nueva'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });

  testWidgets('muestra login de la app de fuerza de ventas', (tester) async {
    await tester.pumpWidget(
      SalesForceApp(dependencies: AppDependencies.mock()),
    );

    expect(find.text('Interbank UC'), findsOneWidget);
    expect(find.text('App Fuerza de Ventas'), findsOneWidget);
    expect(find.text('Bienvenido'), findsOneWidget);
    expect(
      find.text('Ingresa para gestionar tu cartera y solicitudes de credito.'),
      findsOneWidget,
    );
    expect(find.text('0002'), findsOneWidget);
    expect(find.text('Crear una cuenta nueva'), findsNothing);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
