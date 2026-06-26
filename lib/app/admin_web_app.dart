import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'theme/interbank_theme.dart';

class AdminWebApp extends StatelessWidget {
  const AdminWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Banco Andino - Comite de Creditos',
      theme: InterbankTheme.customer(),
      home: const _AdminLoginPage(),
    );
  }
}

class _AdminLoginPage extends StatefulWidget {
  const _AdminLoginPage();

  @override
  State<_AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<_AdminLoginPage> {
  static const _storage = FlutterSecureStorage();
  final _code = TextEditingController(text: '0001');
  final _password = TextEditingController(text: '1234');
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl()}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'codigo_empleado': _code.text.trim(),
          'password': _password.text,
        }),
      );
      if (response.statusCode != 200) {
        setState(() => _error = 'Credenciales invalidas');
        return;
      }
      final data = jsonDecode(response.body) as Map<String, Object?>;
      final advisor = data['asesor'] as Map<String, Object?>;
      final profile = advisor['perfil'] as String;
      if (!{'supervisor', 'administrador', 'super_operador'}.contains(profile)) {
        setState(() => _error = 'Se requiere perfil supervisor/administrador');
        return;
      }
      await _storage.write(
        key: 'admin_jwt',
        value: data['access_token'] as String,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => _AdminDashboard(
            token: data['access_token'] as String,
            advisorName: '${advisor['nombres']} ${advisor['apellidos']}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 420,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Comite de Creditos', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text('Banco Andino - acceso supervisor'),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _code,
                    decoration: const InputDecoration(labelText: 'Codigo de empleado'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contrasena'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: Text(_loading ? 'Ingresando...' : 'Ingresar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminDashboard extends StatefulWidget {
  const _AdminDashboard({required this.token, required this.advisorName});

  final String token;
  final String advisorName;

  @override
  State<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboard> {
  late Future<List<Map<String, Object?>>> _requests;
  String? _filter;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _requests = _fetchRequests();
  }

  Future<List<Map<String, Object?>>> _fetchRequests() async {
    final uri = Uri.parse('${_baseUrl()}/admin/solicitudes').replace(
      queryParameters: _filter == null ? null : {'estado': _filter!},
    );
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode != 200) {
      throw StateError(response.body);
    }
    return (jsonDecode(response.body) as List<Object?>)
        .cast<Map<String, Object?>>();
  }

  Future<void> _decide(
    Map<String, Object?> request,
    String decision,
  ) async {
    final amount = TextEditingController(
      text: decision == 'aprobado'
          ? (request['monto_solicitado'] as num).toStringAsFixed(2)
          : '',
    );
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(decision == 'aprobado' ? 'Aprobar solicitud' : 'Rechazar solicitud'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (decision == 'aprobado')
                TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Monto aprobado'),
                ),
              if (decision == 'aprobado') const SizedBox(height: 12),
              TextField(
                controller: reason,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: decision == 'aprobado' ? 'Observacion' : 'Motivo obligatorio',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmed != true) return;
    final response = await http.post(
      Uri.parse('${_baseUrl()}/admin/solicitudes/${request['id']}/decision'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'decision': decision,
        'monto_aprobado': decision == 'aprobado' ? double.parse(amount.text) : null,
        'motivo': reason.text.trim(),
      }),
    );
    if (response.statusCode != 200 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo decidir: ${response.body}')),
      );
      return;
    }
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comite de Creditos'),
        actions: [
          Center(child: Text(widget.advisorName)),
          const SizedBox(width: 20),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final item in <String?>[null, 'borrador', 'recibido_comite', 'desembolsado', 'rechazado'])
                  ChoiceChip(
                    label: Text(item ?? 'Todas'),
                    selected: _filter == item,
                    onSelected: (_) => setState(() {
                      _filter = item;
                      _reload();
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, Object?>>>(
                future: _requests,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data!.isEmpty) {
                    return const Center(child: Text('No hay solicitudes para este filtro.'));
                  }
                  return ListView.separated(
                    itemCount: snapshot.data!.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = snapshot.data![index];
                      final canDecide = {'recibido_comite', 'enviado', 'en_evaluacion'}
                          .contains(item['estado']);
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text('${item['numero_expediente']} - ${item['cliente_nombre']}'),
                          subtitle: Text(
                            'Estado: ${item['estado']} | Vendedor: ${item['asesor_nombre']}\n'
                            'DNI: ${item['numero_documento']} | Destino: ${item['destino_credito']}\n'
                            'Ingresos: S/ ${item['ingresos_estimados'] ?? 0}',
                          ),
                          trailing: SizedBox(
                            width: 330,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'S/ ${(item['monto_solicitado'] as num).toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(width: 12),
                                if (canDecide) ...[
                                  FilledButton.tonal(
                                    onPressed: () => _decide(item, 'rechazado'),
                                    child: const Text('Rechazar'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    onPressed: () => _decide(item, 'aprobado'),
                                    child: const Text('Aprobar'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _baseUrl() {
  return const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8003',
  );
}
