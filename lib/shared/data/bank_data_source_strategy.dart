import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:postgres/postgres.dart';

import '../../core/business/credit_policy.dart';
import '../../features/auth/data/models/auth_user_model.dart';
import '../../features/auth/domain/entities/auth_requests.dart';
import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/banking/data/models/banking_snapshot_model.dart';
import '../../features/banking/domain/entities/banking_snapshot.dart';
import '../../features/sales/data/models/sales_portfolio_model.dart';
import '../../features/sales/domain/entities/sales_portfolio.dart';
import 'bank_data_source.dart';

enum BankDataProvider { mock, supabase, localPostgres, coreMobileApi }

abstract class BankDataSourceStrategy {
  BankDataProvider get provider;
  BankDataSource createDataSource();
}

class MockDataSourceStrategy implements BankDataSourceStrategy {
  const MockDataSourceStrategy();

  @override
  BankDataProvider get provider => BankDataProvider.mock;

  @override
  BankDataSource createDataSource() => MockBankDataSource();
}

class CoreMobileApiDataSourceStrategy implements BankDataSourceStrategy {
  const CoreMobileApiDataSourceStrategy({required this.baseUrl});

  final String baseUrl;

  @override
  BankDataProvider get provider => BankDataProvider.coreMobileApi;

  @override
  BankDataSource createDataSource() {
    return CoreMobileApiDataSource(baseUrl: baseUrl);
  }
}

class SupabaseDataSourceStrategy implements BankDataSourceStrategy {
  const SupabaseDataSourceStrategy({required this.url, required this.anonKey});

  final String url;
  final String anonKey;

  @override
  BankDataProvider get provider => BankDataProvider.supabase;

  @override
  BankDataSource createDataSource() {
    return SupabaseBankDataSource(url: url, anonKey: anonKey);
  }
}

class LocalPostgresConnectionConfig {
  const LocalPostgresConnectionConfig({
    required this.host,
    required this.database,
    required this.username,
    required this.password,
    this.port = 5432,
    this.requireSsl = false,
  });

  factory LocalPostgresConnectionConfig.androidEmulator({
    required String database,
    required String username,
    required String password,
  }) {
    return LocalPostgresConnectionConfig(
      host: '10.0.2.2',
      database: database,
      username: username,
      password: password,
    );
  }

  factory LocalPostgresConnectionConfig.iosSimulator({
    required String database,
    required String username,
    required String password,
  }) {
    return LocalPostgresConnectionConfig(
      host: 'localhost',
      database: database,
      username: username,
      password: password,
    );
  }

  factory LocalPostgresConnectionConfig.physicalDevice({
    required String hostLanIp,
    required String database,
    required String username,
    required String password,
  }) {
    return LocalPostgresConnectionConfig(
      host: hostLanIp,
      database: database,
      username: username,
      password: password,
    );
  }

  factory LocalPostgresConnectionConfig.fromEnvironment() {
    return const LocalPostgresConnectionConfig(
      host: String.fromEnvironment('PG_HOST', defaultValue: 'localhost'),
      port: int.fromEnvironment('PG_PORT', defaultValue: 5432),
      database: String.fromEnvironment(
        'PG_DATABASE',
        defaultValue: 'bd_appmovil_fventas',
      ),
      username: String.fromEnvironment('PG_USER', defaultValue: 'postgres'),
      password: String.fromEnvironment('PG_PASSWORD', defaultValue: 'postgres'),
      requireSsl: bool.fromEnvironment('PG_SSL', defaultValue: false),
    );
  }

  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final bool requireSsl;
}

class LocalPostgresDataSourceStrategy implements BankDataSourceStrategy {
  const LocalPostgresDataSourceStrategy({required this.config});

  final LocalPostgresConnectionConfig config;

  @override
  BankDataProvider get provider => BankDataProvider.localPostgres;

  @override
  BankDataSource createDataSource() {
    return LocalPostgresBankDataSource(config: config);
  }
}

class MockBankDataSource implements BankDataSource {
  @override
  Future<AuthUser> login(LoginRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final isSalesOfficer =
        request.email.contains('fieldiq') || request.email.contains('oficial');
    return AuthUserModel.fromMap({
      'id': isSalesOfficer ? 'officer-001' : 'customer-001',
      'fullName': isSalesOfficer ? 'Diego Salazar' : 'Valeria Torres',
      'email': request.email,
      'dni': isSalesOfficer ? '70112233' : '74859612',
      'role': isSalesOfficer ? 'salesOfficer' : 'customer',
    });
  }

  @override
  Future<AuthUser> register(RegisterRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return AuthUserModel.fromMap({
      'id': 'customer-new',
      'fullName': request.fullName,
      'email': request.email,
      'dni': request.dni,
      'role': 'customer',
    });
  }

  @override
  Future<CustomerBankingSnapshot> getCustomerSnapshot(String customerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return CustomerBankingSnapshotModel.fromMap({
      'customerName': 'Valeria Torres',
      'totalBalance': 8430.75,
      'savingsAccounts': [
        {
          'id': 'sav-001',
          'name': 'Cuenta Simple Soles',
          'currency': 'S/',
          'balance': 6210.50,
          'accountNumber': '191-3050004522',
          'lastStatementPeriod': 'Mayo 2026',
        },
        {
          'id': 'sav-002',
          'name': 'Ahorro Meta',
          'currency': 'S/',
          'balance': 2220.25,
          'accountNumber': '191-3050007631',
          'lastStatementPeriod': 'Mayo 2026',
        },
      ],
      'movements': [
        {
          'description': 'Deposito planilla',
          'date': '2026-05-20',
          'amount': 3200.00,
          'type': 'deposit',
        },
        {
          'description': 'Pago tarjeta credito',
          'date': '2026-05-18',
          'amount': -480.90,
          'type': 'payment',
        },
        {
          'description': 'Transferencia a Ana Ruiz',
          'date': '2026-05-16',
          'amount': -250.00,
          'type': 'transfer',
        },
      ],
      'credits': [
        {
          'id': 'loan-001',
          'productName': 'Prestamo Personal',
          'principal': 12000.00,
          'outstandingBalance': 6840.30,
          'nextPaymentDate': '2026-06-05',
          'schedule': [
            {
              'installment': 10,
              'dueDate': '2026-05-05',
              'amount': 640.80,
              'paid': true,
            },
            {
              'installment': 11,
              'dueDate': '2026-06-05',
              'amount': 640.80,
              'paid': false,
            },
            {
              'installment': 12,
              'dueDate': '2026-07-05',
              'amount': 640.80,
              'paid': false,
            },
          ],
        },
      ],
      'paymentServices': [
        {'name': 'Luz del Sur', 'category': 'Servicio', 'amount': 136.40},
        {'name': 'Movistar Hogar', 'category': 'Servicio', 'amount': 119.90},
        {
          'name': 'Universidad Continental',
          'category': 'Educacion',
          'amount': 780.00,
        },
      ],
      'loanRequests': const [],
    });
  }

  @override
  Future<void> createCustomerOperation({
    required String originAccount,
    required String? destinationAccount,
    required String type,
    required double amount,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  @override
  Future<void> createCustomerLoanRequest({
    required double amount,
    required int termMonths,
    required String purpose,
    required String businessType,
    required String businessName,
    required double income,
  }) async {}

  @override
  Future<void> completeAssignedApplication({
    required String applicationId,
    required double income,
    required double expenses,
    required double assets,
    required double? latitude,
    required double? longitude,
  }) async {}

  @override
  Future<SalesPortfolioSnapshot> getSalesPortfolio(String officerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return SalesPortfolioSnapshotModel.fromMap({
      'officerName': 'Diego Salazar',
      'dailyVisits': [
        {
          'id': 'visit-001',
          'customerName': 'Bodega San Carlos',
          'address': 'Av. Ferrocarril 1250, Huancayo',
          'visitTime': '09:30',
          'reason': 'Renovacion de credito capital de trabajo',
          'creditFile': {
            'score': 712,
            'riskLevel': 'Bajo',
            'activeProducts': ['Credito pyme', 'Cuenta negocio'],
            'paymentBehavior': 'Puntual en 11 de 12 cuotas',
          },
        },
        {
          'id': 'visit-002',
          'customerName': 'Textiles Mantaro',
          'address': 'Jr. Ica 420, El Tambo',
          'visitTime': '11:45',
          'reason': 'Levantamiento de documentos legales',
          'creditFile': {
            'score': 665,
            'riskLevel': 'Medio',
            'activeProducts': ['Credito activo'],
            'paymentBehavior': 'Una mora menor a 8 dias',
          },
        },
        {
          'id': 'visit-003',
          'customerName': 'Distribuidora Los Andes',
          'address': 'Ca. Real 890, Chilca',
          'visitTime': '15:20',
          'reason': 'Solicitud nueva en campo',
          'creditFile': {
            'score': 734,
            'riskLevel': 'Bajo',
            'activeProducts': ['Cuenta corriente'],
            'paymentBehavior': 'Sin atrasos reportados',
          },
        },
      ],
      'activeApplications': [
        {
          'id': 'app-1042',
          'customerName': 'Bodega San Carlos',
          'amount': 18000.00,
          'status': 'underReview',
          'bureauCheck': {
            'provider': 'Buro demo',
            'result': 'Apto con politica regular',
            'checkedAt': '2026-05-22T09:40:00',
          },
          'transmitted': true,
        },
        {
          'id': 'app-1043',
          'customerName': 'Textiles Mantaro',
          'amount': 12500.00,
          'status': 'approved',
          'bureauCheck': {
            'provider': 'Buro demo',
            'result': 'Apto',
            'checkedAt': '2026-05-22T11:55:00',
          },
          'transmitted': true,
        },
      ],
    });
  }

  @override
  Future<CreditApplication> submitCreditApplication(
    CreditApplicationDraft draft,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return CreditApplicationModel.fromMap({
      'id': 'app-${DateTime.now().millisecondsSinceEpoch}',
      'customerName': draft.customerName,
      'amount': draft.amount,
      'status': 'sent',
      'bureauCheck': {
        'provider': 'Buro demo',
        'result': draft.amount <= 20000 ? 'Apto' : 'Requiere evaluacion manual',
        'checkedAt': DateTime.now().toIso8601String(),
      },
      'transmitted': !draft.offlineCaptured,
    });
  }
}

class CoreMobileApiDataSource implements BankDataSource {
  CoreMobileApiDataSource({required String baseUrl})
    : baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), '');

  final String baseUrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _salesToken;
  String? _customerToken;
  AuthUser? _lastSalesUser;
  AuthUser? _lastCustomerUser;

  @override
  Future<AuthUser> login(LoginRequest request) async {
    final looksLikeSalesLogin =
        request.email.contains('fieldiq') ||
        request.email.contains('oficial') ||
        RegExp(r'^\d{4}$').hasMatch(request.email.trim());

    if (looksLikeSalesLogin) {
      final code = RegExp(r'^\d{4}$').hasMatch(request.email.trim())
          ? request.email.trim()
          : '0001';
      final data = await _postJson('/auth/login', {
        'codigo_empleado': code,
        'password': request.password,
      });
      _salesToken = data['access_token'] as String?;
      await _secureStorage.write(key: 'sales_jwt', value: _salesToken);
      final advisor = data['asesor'] as Map<String, Object?>;
      final user = AuthUserModel.fromMap({
        'id': advisor['id'],
        'fullName': '${advisor['nombres']} ${advisor['apellidos']}',
        'email': request.email,
        'dni': advisor['codigo_empleado'],
        'role': 'salesOfficer',
      });
      _lastSalesUser = user;
      return user;
    }

    final document = (request.dni?.isNotEmpty ?? false)
        ? request.dni!
        : request.email.trim();
    final data = await _postJson('/cliente/login', {
      'numero_documento': document,
      'password': request.password,
    });
    _customerToken = data['access_token'] as String?;
    await _secureStorage.write(key: 'customer_jwt', value: _customerToken);
    final customer = data['cliente'] as Map<String, Object?>;
    final user = AuthUserModel.fromMap({
      'id': customer['id'],
      'fullName': '${customer['nombres']} ${customer['apellidos']}',
      'email': customer['email'] ?? request.email,
      'dni': customer['numero_documento'],
      'role': 'customer',
    });
    _lastCustomerUser = user;
    return user;
  }

  @override
  Future<AuthUser> register(RegisterRequest request) {
    throw UnimplementedError(
      'El Core Mobile FastAPI no expone registro publico de usuarios.',
    );
  }

  @override
  Future<CustomerBankingSnapshot> getCustomerSnapshot(String customerId) async {
    final profile = await _getJson('/cliente/perfil', token: _customerToken);
    final accounts = await _getList('/cliente/cuentas', token: _customerToken);
    final credits = await _getList('/cliente/creditos', token: _customerToken);
    final movements = await _getList(
      '/cliente/movimientos',
      token: _customerToken,
    );
    final cards = await _getList('/cliente/tarjetas', token: _customerToken);
    final notifications = await _getList(
      '/cliente/notificaciones',
      token: _customerToken,
    );
    final loanRequests = await _getList(
      '/cliente/solicitudes',
      token: _customerToken,
    );

    final mappedAccounts = accounts.map((account) {
      final balance =
          _num(account['saldo_capital']) + _num(account['saldo_interes']);
      return {
        'id': account['id'],
        'name': account['tipo_cuenta'] ?? 'Cuenta ahorro',
        'currency': _currency(account['moneda']),
        'balance': balance,
        'accountNumber': account['cod_cuenta_ahorro'],
        'lastStatementPeriod': account['estado'] ?? 'Core Mobile',
      };
    }).toList();

    final mappedCredits = <Map<String, Object?>>[];
    for (final credit in credits) {
      final schedule = await _getList(
        '/cliente/creditos/${credit['cod_cuenta_credito']}/cronograma',
        token: _customerToken,
      );
      mappedCredits.add({
        'id': credit['id'],
        'productName': credit['producto'] ?? 'Credito',
        'principal': _num(credit['monto_desembolsado']),
        'outstandingBalance': _num(credit['saldo_total']),
        'nextPaymentDate': _nextPaymentDate(schedule),
        'schedule': schedule.map((item) {
          return {
            'installment': item['nro_cuota'],
            'dueDate': item['fecha_vencimiento'],
            'amount': _num(item['monto_cuota']),
            'paid': item['estado_cuota'] == 'pagada',
          };
        }).toList(),
      });
    }

    final mappedMovements = movements.map((movement) {
      return {
        'description': movement['concepto'] ?? movement['tipo'] ?? 'Movimiento',
        'date': (movement['fecha_operacion'] as String).split('T').first,
        'amount': _movementAmount(movement),
        'type': _movementType(movement['tipo'] as String?),
      };
    }).toList();

    final paymentServices = [
      ...cards.map((card) {
        return {
          'name': 'Tarjeta ${card['numero_enmascarado']}',
          'category': card['marca'] ?? 'Tarjeta',
          'amount': _num(card['saldo_utilizado']),
        };
      }),
      ...notifications.take(3).map((notification) {
        return {
          'name': notification['titulo'] ?? 'Notificacion',
          'category': notification['tipo'] ?? 'Aviso',
          'amount': 0.0,
        };
      }),
    ];

    return CustomerBankingSnapshotModel.fromMap({
      'customerName':
          '${profile['nombres']} ${profile['apellidos']}'.trim().isEmpty
          ? _lastCustomerUser?.fullName ?? 'Cliente'
          : '${profile['nombres']} ${profile['apellidos']}',
      'totalBalance': mappedAccounts.fold<double>(
        0,
        (sum, account) => sum + _num(account['balance']),
      ),
      'savingsAccounts': mappedAccounts,
      'movements': mappedMovements,
      'credits': mappedCredits,
      'paymentServices': paymentServices,
      'loanRequests': loanRequests.map((request) {
        return {
          'id': request['id'],
          'expedient': request['numero_expediente'] ?? '',
          'amount': _num(request['monto_solicitado']),
          'approvedAmount': _num(request['monto_aprobado']),
          'termMonths': request['plazo_meses'] ?? 0,
          'purpose': request['destino_credito'] ?? '',
          'status': request['estado'],
          'rejectionReason': request['motivo_rechazo'],
          'advisorName': request['asesor_nombre'] ?? '',
          'createdAt': request['created_at'],
        };
      }).toList(),
    });
  }

  @override
  Future<SalesPortfolioSnapshot> getSalesPortfolio(String officerId) async {
    final portfolio = await _getList('/cartera', token: _salesToken);
    final applications = await _getList('/solicitudes', token: _salesToken);

    return SalesPortfolioSnapshotModel.fromMap({
      'officerName': _lastSalesUser?.fullName ?? 'Asesor',
      'dailyVisits': portfolio.map((item) {
        return {
          'id': item['id'],
          'customerName': item['cliente_nombre'],
          'address': _locationLabel(item),
          'visitTime': '#${item['orden_manual'] ?? '-'}',
          'reason': '${item['tipo_gestion']} | ${item['prioridad']}',
          'creditFile': {
            'score': item['score_prioridad'] ?? 0,
            'riskLevel': item['prioridad'] ?? 'N/D',
            'activeProducts': [
              'S/ ${_num(item['monto_credito']).toStringAsFixed(2)}',
            ],
            'paymentBehavior': item['estado_visita'] ?? 'pendiente',
          },
        };
      }).toList(),
      'activeApplications': applications.map((item) {
        return {
          'id': item['id'],
          'customerName': item['cliente_nombre'],
          'amount': _num(item['monto_solicitado']),
          'status': _apiApplicationStatus(item['estado'] as String?),
          'createdAt': item['created_at'],
          'bureauCheck': {
            'provider': 'Core Mobile',
            'result': item['numero_expediente'] ?? item['estado'] ?? 'Enviado',
            'checkedAt': item['created_at'] ?? DateTime.now().toIso8601String(),
          },
          'transmitted': true,
        };
      }).toList(),
    });
  }

  @override
  Future<void> createCustomerOperation({
    required String originAccount,
    required String? destinationAccount,
    required String type,
    required double amount,
  }) async {
    await _postJson('/cliente/operaciones', {
      'cod_cuenta_origen': originAccount,
      'cod_cuenta_destino': destinationAccount,
      'tipo': type,
      'monto': amount,
      'moneda': 'PEN',
    }, token: _customerToken);
  }

  @override
  Future<void> createCustomerLoanRequest({
    required double amount,
    required int termMonths,
    required String purpose,
    required String businessType,
    required String businessName,
    required double income,
  }) async {
    await _postJson('/cliente/solicitudes', {
      'monto_solicitado': amount,
      'plazo_meses': termMonths,
      'destino_credito': purpose,
      'tipo_negocio': businessType,
      'nombre_negocio': businessName,
      'ingresos_estimados': income,
    }, token: _customerToken);
  }

  @override
  Future<void> completeAssignedApplication({
    required String applicationId,
    required double income,
    required double expenses,
    required double assets,
    required double? latitude,
    required double? longitude,
  }) async {
    await _postJson('/solicitudes/$applicationId/completar', {
      'ingresos_estimados': income,
      'gastos_mensuales': expenses,
      'patrimonio_estimado': assets,
      'lat': latitude,
      'lng': longitude,
      'firma_cliente_base64': 'firma-web-$applicationId',
      'consentimiento_base64': 'consentimiento-web-$applicationId',
    }, token: _salesToken);
  }

  @override
  Future<CreditApplication> submitCreditApplication(
    CreditApplicationDraft draft,
  ) async {
    const policy = CreditPolicies.businessWorkingCapital;
    const termMonths = 12;
    final installment = CreditPolicies.frenchInstallment(
      amount: draft.amount,
      termMonths: termMonths,
      tea: policy.defaultTea,
    );
    final parts = draft.customerName.trim().split(RegExp(r'\s+'));
    final preEval = await _postJson('/pre-evaluar', {
      'numero_documento': draft.dni,
      'nombres': draft.customerName,
      'tipo_negocio': draft.businessActivity,
      'ingresos_estimados': draft.amount * 0.35,
      'monto_solicitado': draft.amount,
      'destino_credito': 'Capital de trabajo',
    }, token: _salesToken);
    final bureau = await _postJson('/buro/consulta', {
      'dni': draft.dni,
    }, token: _salesToken);
    final data = await _postJson('/solicitudes', {
      'numero_documento': draft.dni,
      'nombres': parts.isEmpty ? draft.customerName : parts.first,
      'apellidos': parts.length <= 1 ? '' : parts.skip(1).join(' '),
      'telefono': draft.phone,
      'tipo_negocio': draft.businessActivity,
      'nombre_negocio': draft.customerName,
      'ingresos_estimados': draft.amount * 0.35,
      'monto_solicitado': draft.amount,
      'plazo_meses': termMonths,
      'moneda': 'PEN',
      'tipo_cuota': 'mensual',
      'garantia': 'sin_garantia',
      'destino_credito': 'Capital de trabajo',
      'cuota_estimada': installment,
      'tea_referencial': policy.defaultTea,
      'firma_cliente_base64': 'firma-demo-${draft.dni}',
    }, token: _salesToken);

    return CreditApplicationModel.fromMap({
      'id': data['id'],
      'customerName': draft.customerName,
      'amount': draft.amount,
      'status': data['estado'] ?? 'sent',
      'bureauCheck': {
        'provider': 'SBS + lista negra',
        'result':
            '${bureau['calificacion_sbs']} | ${preEval['calificacion']} | ${data['numero_expediente']}',
        'checkedAt': DateTime.now().toIso8601String(),
      },
      'transmitted': !draft.offlineCaptured,
    });
  }

  Future<Map<String, Object?>> _postJson(
    String path,
    Map<String, Object?> body, {
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    return _decodeMap(response);
  }

  Future<Map<String, Object?>> _getJson(String path, {String? token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
    );
    return _decodeMap(response);
  }

  Future<List<Map<String, Object?>>> _getList(
    String path, {
    String? token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
    );
    final decoded = _decode(response);
    return (decoded as List<Object?>).cast<Map<String, Object?>>();
  }

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, Object?> _decodeMap(http.Response response) {
    return (_decode(response) as Map<String, Object?>);
  }

  Object? _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Core Mobile API ${response.statusCode}: ${response.body}',
      );
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Object?;
  }

  static double _num(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _currency(Object? value) {
    return value == 'PEN' ? 'S/' : value?.toString() ?? 'S/';
  }

  static String _nextPaymentDate(List<Map<String, Object?>> schedule) {
    if (schedule.isEmpty)
      return DateTime.now().toIso8601String().split('T').first;
    return schedule.firstWhere(
          (item) => item['estado_cuota'] != 'pagada',
          orElse: () => schedule.first,
        )['fecha_vencimiento']
        as String;
  }

  static double _movementAmount(Map<String, Object?> movement) {
    final amount = _num(movement['monto']);
    return switch (movement['tipo']) {
      'DEB' || 'TRF' => -amount,
      _ => amount,
    };
  }

  static String _movementType(String? type) {
    return switch (type) {
      'DEB' => 'withdrawal',
      'TRF' => 'transfer',
      'PAG' => 'payment',
      _ => 'deposit',
    };
  }

  static String _apiApplicationStatus(String? status) {
    return switch (status) {
      'aprobada' => 'approved',
      'desembolsada' => 'disbursed',
      'en_evaluacion' => 'underReview',
      'recibido_comite' => 'underReview',
      'borrador' => 'sent',
      'enviado' => 'sent',
      _ => 'sent',
    };
  }

  static String _locationLabel(Map<String, Object?> item) {
    final lat = item['lat'];
    final lng = item['lng'];
    if (lat == null || lng == null) return 'Ubicacion por confirmar';
    return '$lat, $lng';
  }
}

class SupabaseBankDataSource implements BankDataSource {
  const SupabaseBankDataSource({required this.url, required this.anonKey});

  final String url;
  final String anonKey;

  Never _pending() {
    throw UnimplementedError(
      'Implementar aqui el cliente Supabase. La app no depende de Supabase '
      'fuera de esta estrategia, por lo que puede reemplazarse por REST, '
      'Firebase u otro proveedor creando otra BankDataSourceStrategy.',
    );
  }

  @override
  Future<AuthUser> login(LoginRequest request) => _pending();

  @override
  Future<AuthUser> register(RegisterRequest request) => _pending();

  @override
  Future<CustomerBankingSnapshot> getCustomerSnapshot(String customerId) {
    return _pending();
  }

  @override
  Future<void> createCustomerOperation({
    required String originAccount,
    required String? destinationAccount,
    required String type,
    required double amount,
  }) {
    return _pending();
  }

  @override
  Future<void> createCustomerLoanRequest({
    required double amount,
    required int termMonths,
    required String purpose,
    required String businessType,
    required String businessName,
    required double income,
  }) {
    return _pending();
  }

  @override
  Future<void> completeAssignedApplication({
    required String applicationId,
    required double income,
    required double expenses,
    required double assets,
    required double? latitude,
    required double? longitude,
  }) {
    return _pending();
  }

  @override
  Future<SalesPortfolioSnapshot> getSalesPortfolio(String officerId) {
    return _pending();
  }

  @override
  Future<CreditApplication> submitCreditApplication(
    CreditApplicationDraft draft,
  ) {
    return _pending();
  }
}

class LocalPostgresBankDataSource implements BankDataSource {
  LocalPostgresBankDataSource({required this.config});

  final LocalPostgresConnectionConfig config;
  Connection? _connection;

  Future<Connection> get _conn async {
    final current = _connection;
    if (current != null && current.isOpen) return current;

    final connection = await Connection.open(
      Endpoint(
        host: config.host,
        port: config.port,
        database: config.database,
        username: config.username,
        password: config.password,
      ),
      settings: ConnectionSettings(
        sslMode: config.requireSsl ? SslMode.require : SslMode.disable,
        connectTimeout: const Duration(seconds: 8),
        queryTimeout: const Duration(seconds: 20),
      ),
    );
    _connection = connection;
    return connection;
  }

  @override
  Future<AuthUser> login(LoginRequest request) async {
    final rows = await (await _conn).execute(
      Sql.named('''
        select
          u.id::text,
          u.email,
          u.nombre,
          u.apellido,
          u.rol,
          coalesce(pc.dni, '') as dni
        from public.usuarios_mock u
        left join public.perfiles_clientes pc on pc.user_id = u.id
        where lower(u.email) = lower(@email:text)
          and u.activo = true
        limit 1
      '''),
      parameters: {'email': request.email},
    );

    if (rows.isEmpty) {
      throw StateError('Usuario no encontrado en PostgreSQL local.');
    }

    return _authUserFromRow(rows.first.toColumnMap());
  }

  @override
  Future<AuthUser> register(RegisterRequest request) async {
    final names = _splitFullName(request.fullName);
    final rows = await (await _conn).execute(
      Sql.named('''
        insert into public.usuarios_mock
          (email, nombre, apellido, password_hash, rol)
        values
          (@email:text, @nombre:text, @apellido:text, @password:text, 'cliente')
        returning id::text, email, nombre, apellido, rol
      '''),
      parameters: {
        'email': request.email,
        'nombre': names.$1,
        'apellido': names.$2,
        'password': request.password,
      },
    );

    final user = rows.first.toColumnMap();
    await (await _conn).execute(
      Sql.named('''
        insert into public.perfiles_clientes
          (user_id, nombres, apellidos, dni, estado_cliente)
        values
          (@userId:uuid, @nombre:text, @apellido:text, @dni:text, 'prospecto')
        on conflict (user_id) do nothing
      '''),
      parameters: {
        'userId': user['id'],
        'nombre': names.$1,
        'apellido': names.$2,
        'dni': request.dni,
      },
    );

    return _authUserFromRow({...user, 'dni': request.dni});
  }

  @override
  Future<CustomerBankingSnapshot> getCustomerSnapshot(String customerId) async {
    final resolvedCustomerId = await _resolveCustomerId(customerId);
    final user = await _fetchUser(resolvedCustomerId);
    final accounts = await _fetchAccounts(resolvedCustomerId);
    final movements = await _fetchMovements(resolvedCustomerId);
    final credits = await _fetchCredits(resolvedCustomerId);
    final services = await _fetchPaymentServices(resolvedCustomerId);

    return CustomerBankingSnapshotModel.fromMap({
      'customerName': user['fullName'],
      'totalBalance': accounts.fold<double>(
        0,
        (sum, account) => sum + _toDouble(account['balance']),
      ),
      'savingsAccounts': accounts,
      'movements': movements,
      'credits': credits,
      'paymentServices': services,
      'loanRequests': const [],
    });
  }

  @override
  Future<void> createCustomerOperation({
    required String originAccount,
    required String? destinationAccount,
    required String type,
    required double amount,
  }) async {
    await (await _conn).execute(
      Sql.named('''
        insert into public.pagos (user_id, servicio, categoria, monto)
        select u.id, @destino:text, @tipo:text, @monto:numeric
        from public.usuarios_mock u
        where u.rol = 'cliente'
        order by u.created_at
        limit 1
      '''),
      parameters: {
        'destino': destinationAccount ?? originAccount,
        'tipo': type,
        'monto': amount,
      },
    );
  }

  @override
  Future<void> createCustomerLoanRequest({
    required double amount,
    required int termMonths,
    required String purpose,
    required String businessType,
    required String businessName,
    required double income,
  }) async {
    throw UnsupportedError('Use Core Mobile API para solicitudes de cliente.');
  }

  @override
  Future<void> completeAssignedApplication({
    required String applicationId,
    required double income,
    required double expenses,
    required double assets,
    required double? latitude,
    required double? longitude,
  }) async {
    throw UnsupportedError('Use Core Mobile API para completar expedientes.');
  }

  @override
  Future<SalesPortfolioSnapshot> getSalesPortfolio(String officerId) async {
    final advisor = await _resolveAdvisor(officerId);
    final visits = await _fetchDailyVisits(advisor);
    final applications = await _fetchActiveApplications(advisor);

    return SalesPortfolioSnapshotModel.fromMap({
      'officerName': advisor.name,
      'dailyVisits': visits,
      'activeApplications': applications,
    });
  }

  @override
  Future<CreditApplication> submitCreditApplication(
    CreditApplicationDraft draft,
  ) async {
    final advisor = await _resolveAdvisor(draft.officerId);
    final inserted = await (await _conn).execute(
      Sql.named('''
        insert into public.fichas_campo (
          asesor_id,
          prospecto_nombre,
          prospecto_dni,
          prospecto_telefono,
          distrito,
          tipo_visita,
          negocio_nombre,
          negocio_rubro,
          ingreso_declarado,
          gasto_declarado,
          estado_ficha,
          monto_solicitado,
          observaciones,
          creada_offline,
          sincronizada_at
        )
        values (
          @advisorUserId:uuid,
          @customerName:text,
          @dni:text,
          @phone:text,
          'Huancayo',
          'prospeccion',
          @customerName:text,
          @businessActivity:text,
          0,
          0,
          @status:text,
          @amount:numeric,
          @observations:text,
          @offline:boolean,
          case when @offline:boolean then null else now() end
        )
        returning id::text, created_at
      '''),
      parameters: {
        'advisorUserId': advisor.userId,
        'customerName': draft.customerName,
        'dni': draft.dni,
        'phone': draft.phone,
        'businessActivity': draft.businessActivity,
        'status': draft.offlineCaptured ? 'borrador' : 'sincronizada',
        'amount': draft.amount,
        'observations': 'Solicitud creada desde Flutter local.',
        'offline': draft.offlineCaptured,
      },
    );

    final row = inserted.first.toColumnMap();
    return CreditApplicationModel.fromMap({
      'id': row['id'] as String,
      'customerName': draft.customerName,
      'amount': draft.amount,
      'status': draft.offlineCaptured ? 'sent' : 'underReview',
      'bureauCheck': {
        'provider': 'PostgreSQL local',
        'result': draft.offlineCaptured
            ? 'Guardado offline para sincronizacion'
            : 'Ficha sincronizada en PostgreSQL',
        'checkedAt': _dateTime(row['created_at']).toIso8601String(),
      },
      'transmitted': !draft.offlineCaptured,
    });
  }

  AuthUser _authUserFromRow(Map<String, Object?> row) {
    final role = row['rol'] == 'asesor' || row['rol'] == 'admin'
        ? 'salesOfficer'
        : 'customer';

    return AuthUserModel.fromMap({
      'id': row['id'] as String,
      'fullName': '${row['nombre']} ${row['apellido']}',
      'email': row['email'] as String,
      'dni': row['dni'] as String? ?? '',
      'role': role,
    });
  }

  Future<String> _resolveCustomerId(String preferredId) async {
    final rows = await (await _conn).execute(
      Sql.named('''
        select u.id::text
        from public.usuarios_mock u
        join public.perfiles_clientes pc on pc.user_id = u.id
        where u.id = @preferredId:uuid
          and u.rol = 'cliente'
        limit 1
      '''),
      parameters: {'preferredId': preferredId},
    );
    if (rows.isNotEmpty) return rows.first.toColumnMap()['id'] as String;

    final fallback = await (await _conn).execute('''
      select u.id::text
      from public.usuarios_mock u
      join public.perfiles_clientes pc on pc.user_id = u.id
      where u.rol = 'cliente'
      order by u.created_at
      limit 1
    ''');
    if (fallback.isEmpty) {
      throw StateError('No hay clientes cargados en PostgreSQL local.');
    }
    return fallback.first.toColumnMap()['id'] as String;
  }

  Future<Map<String, Object?>> _fetchUser(String userId) async {
    final rows = await (await _conn).execute(
      Sql.named('''
        select
          u.nombre || ' ' || u.apellido as full_name
        from public.usuarios_mock u
        where u.id = @userId:uuid
        limit 1
      '''),
      parameters: {'userId': userId},
    );
    return {'fullName': rows.first.toColumnMap()['full_name'] as String};
  }

  Future<List<Map<String, Object?>>> _fetchAccounts(String userId) async {
    final rows = await (await _conn).execute(
      Sql.named('''
        select
          id::text,
          initcap(tipo) as name,
          case when moneda = 'PEN' then 'S/' else moneda end as currency,
          saldo,
          numero_cuenta,
          to_char(created_at, 'Mon YYYY') as period
        from public.cuentas
        where user_id = @userId:uuid
        order by created_at
      '''),
      parameters: {'userId': userId},
    );

    final accounts = rows.map((row) {
      final data = row.toColumnMap();
      return {
        'id': data['id'] as String,
        'name': 'Cuenta ${data['name']}',
        'currency': data['currency'] as String,
        'balance': _toDouble(data['saldo']),
        'accountNumber': data['numero_cuenta'] as String,
        'lastStatementPeriod': data['period'] as String,
      };
    }).toList();

    if (accounts.isNotEmpty) return accounts;

    final fallback = await (await _conn).execute(
      Sql.named('''
        select coalesce(avg(saldo_promedio), 0) as saldo
        from public.movimientos_mensuales
        where user_id = @userId:uuid
      '''),
      parameters: {'userId': userId},
    );
    final balance = _toDouble(fallback.first.toColumnMap()['saldo']);
    return [
      {
        'id': 'perfil-$userId',
        'name': 'Cuenta negocio demo',
        'currency': 'S/',
        'balance': balance,
        'accountNumber': 'BD local - scoring',
        'lastStatementPeriod': 'Demo PostgreSQL',
      },
    ];
  }

  Future<List<Map<String, Object?>>> _fetchMovements(String userId) async {
    final rows = await (await _conn).execute(
      Sql.named('''
        select
          periodo,
          total_creditos,
          total_debitos,
          num_transacciones
        from public.movimientos_mensuales
        where user_id = @userId:uuid
        order by periodo desc
        limit 6
      '''),
      parameters: {'userId': userId},
    );

    return rows.map((row) {
      final data = row.toColumnMap();
      final credits = _toDouble(data['total_creditos']);
      final debits = _toDouble(data['total_debitos']);
      return {
        'description':
            'Resumen ${data['periodo']} (${data['num_transacciones']} mov.)',
        'date': '${data['periodo']}-01',
        'amount': credits - debits,
        'type': credits >= debits ? 'deposit' : 'payment',
      };
    }).toList();
  }

  Future<List<Map<String, Object?>>> _fetchCredits(String userId) async {
    final rows = await (await _conn).execute(
      Sql.named('''
        select
          cp.id::text,
          cp.monto_preaprobado,
          cp.cuota_estimada,
          cp.vigente_hasta,
          cp.estado
        from public.creditos_preaprobados cp
        where cp.cliente_user_id = @userId:uuid
        order by cp.created_at desc
        limit 3
      '''),
      parameters: {'userId': userId},
    );

    return rows.map((row) {
      final data = row.toColumnMap();
      final amount = _toDouble(data['monto_preaprobado']);
      return {
        'id': data['id'] as String,
        'productName': 'Credito preaprobado ${data['estado']}',
        'principal': amount,
        'outstandingBalance': amount,
        'nextPaymentDate': _dateOnly(data['vigente_hasta']),
        'schedule': [
          {
            'installment': 1,
            'dueDate': _dateOnly(data['vigente_hasta']),
            'amount': _toDouble(data['cuota_estimada']),
            'paid': false,
          },
        ],
      };
    }).toList();
  }

  Future<List<Map<String, Object?>>> _fetchPaymentServices(
    String userId,
  ) async {
    final rows = await (await _conn).execute(
      Sql.named('''
        select servicio, monto
        from public.pagos
        where user_id = @userId:uuid
        order by fecha desc
        limit 5
      '''),
      parameters: {'userId': userId},
    );

    final services = rows.map((row) {
      final data = row.toColumnMap();
      return {
        'name': data['servicio'] as String,
        'category': 'Servicio',
        'amount': _toDouble(data['monto']),
      };
    }).toList();

    if (services.isNotEmpty) return services;
    return const [
      {'name': 'Scoring transaccional', 'category': 'Demo', 'amount': 0.0},
      {'name': 'Ficha de campo', 'category': 'Demo', 'amount': 0.0},
    ];
  }

  Future<_AdvisorRef> _resolveAdvisor(String? preferredUserId) async {
    final rows = await (await _conn).execute(
      Sql.named('''
        select
          um.id::text as user_id,
          an.id::text as advisor_id,
          um.nombre || ' ' || um.apellido as name
        from public.asesores_negocio an
        join public.usuarios_mock um on um.id = an.user_id
        where (@preferredUserId:uuid is null or um.id = @preferredUserId:uuid)
          and an.activo = true
        order by
          case when um.id = @preferredUserId:uuid then 0 else 1 end,
          an.codigo_asesor
        limit 1
      '''),
      parameters: {'preferredUserId': preferredUserId},
    );

    if (rows.isEmpty) {
      throw StateError('No hay asesores activos en PostgreSQL local.');
    }
    final row = rows.first.toColumnMap();
    return _AdvisorRef(
      userId: row['user_id'] as String,
      advisorId: row['advisor_id'] as String,
      name: row['name'] as String,
    );
  }

  Future<List<Map<String, Object?>>> _fetchDailyVisits(
    _AdvisorRef advisor,
  ) async {
    final rows = await (await _conn).execute(
      Sql.named('''
        select
          rp.id::text,
          coalesce(
            pc.nombres || ' ' || pc.apellidos,
            rp.prospecto_nombre,
            'Cliente sin nombre'
          ) as customer_name,
          coalesce(rp.referencia_dir, 'Sin direccion registrada') as address,
          coalesce(to_char(rp.hora_sugerida, 'HH24:MI'), '--:--') as visit_time,
          rp.tipo_visita,
          rp.monto_estimado,
          coalesce(st.score, pc.puntaje_crediticio, 0) as score,
          coalesce(st.segmento, 'N/D') as segment,
          coalesce(st.recomendacion, 'evaluar_presencial') as recommendation,
          coalesce(pc.tipo_negocio, 'prospecto') as business_type,
          coalesce(pc.zona_negocio, 'zona por validar') as business_zone
        from public.rutas_planificadas rp
        left join public.perfiles_clientes pc on pc.user_id = rp.cliente_user_id
        left join public.scores_transaccionales st
          on st.user_id = rp.cliente_user_id
        where rp.asesor_id = @advisorId:uuid
          and rp.fecha_ruta = current_date
        order by rp.hora_sugerida nulls last
      '''),
      parameters: {'advisorId': advisor.advisorId},
    );

    return rows.map((row) {
      final data = row.toColumnMap();
      return {
        'id': data['id'] as String,
        'customerName': data['customer_name'] as String,
        'address': data['address'] as String,
        'visitTime': data['visit_time'] as String,
        'reason':
            '${data['tipo_visita']} | S/ ${_toDouble(data['monto_estimado']).toStringAsFixed(0)}',
        'creditFile': {
          'score': _toDouble(data['score']).round(),
          'riskLevel': data['segment'] as String,
          'activeProducts': [
            data['business_type'] as String,
            data['business_zone'] as String,
          ],
          'paymentBehavior': _labelRecommendation(
            data['recommendation'] as String,
          ),
        },
      };
    }).toList();
  }

  Future<List<Map<String, Object?>>> _fetchActiveApplications(
    _AdvisorRef advisor,
  ) async {
    final rows = await (await _conn).execute(
      Sql.named('''
        select
          fc.id::text,
          coalesce(
            pc.nombres || ' ' || pc.apellidos,
            fc.prospecto_nombre,
            fc.negocio_nombre,
            'Cliente sin nombre'
          ) as customer_name,
          fc.monto_solicitado,
          fc.estado_ficha,
          fc.creada_offline,
          fc.created_at,
          coalesce(st.recomendacion, cp.estado, 'evaluacion_local') as result
        from public.fichas_campo fc
        left join public.perfiles_clientes pc on pc.user_id = fc.cliente_user_id
        left join public.scores_transaccionales st
          on st.user_id = fc.cliente_user_id
        left join public.creditos_preaprobados cp on cp.ficha_id = fc.id
        where fc.asesor_id = @advisorUserId:uuid
        order by fc.created_at desc
        limit 8
      '''),
      parameters: {'advisorUserId': advisor.userId},
    );

    return rows.map((row) {
      final data = row.toColumnMap();
      return {
        'id': data['id'] as String,
        'customerName': data['customer_name'] as String,
        'amount': _toDouble(data['monto_solicitado']),
        'status': _applicationStatus(data['estado_ficha'] as String),
        'bureauCheck': {
          'provider': 'Scoring PostgreSQL',
          'result': _labelRecommendation(data['result'] as String),
          'checkedAt': _dateTime(data['created_at']).toIso8601String(),
        },
        'transmitted': !(data['creada_offline'] as bool),
      };
    }).toList();
  }

  static (String, String) _splitFullName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return (parts.first, '-');
    return (parts.first, parts.skip(1).join(' '));
  }

  static double _toDouble(Object? value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _dateTime(Object? value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  static String _dateOnly(Object? value) {
    final date = _dateTime(value);
    return date.toIso8601String().split('T').first;
  }

  static String _labelRecommendation(String value) {
    return switch (value) {
      'pre_aprobado_inmediato' => 'Preaprobado inmediato',
      'aprobacion_rapida' => 'Aprobacion rapida',
      'evaluar_con_garantias' => 'Evaluar con garantias',
      'requiere_comite' => 'Requiere comite',
      'rechazar' => 'Rechazar',
      'pre-aprobado' => 'Preaprobado',
      'en_comite' => 'En comite',
      _ => value.replaceAll('_', ' '),
    };
  }

  static String _applicationStatus(String value) {
    return switch (value) {
      'completada' => 'underReview',
      'sincronizada' => 'sent',
      'aprobada' => 'approved',
      'desembolsada' => 'disbursed',
      _ => 'sent',
    };
  }
}

class _AdvisorRef {
  const _AdvisorRef({
    required this.userId,
    required this.advisorId,
    required this.name,
  });

  final String userId;
  final String advisorId;
  final String name;
}
