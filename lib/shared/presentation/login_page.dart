import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../app/theme/interbank_theme.dart';
import '../../core/validation/validators.dart';
import '../../features/auth/domain/entities/auth_requests.dart';
import '../../features/auth/domain/entities/auth_user.dart';
import 'customer_shell.dart';
import 'interbank_logo.dart';
import 'sales_shell.dart';

enum LoginDestination { customerBanking, salesForce }

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.dependencies,
    required this.destination,
  });

  final AppDependencies dependencies;
  final LoginDestination destination;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late final TextEditingController _emailController;
  final _dniController = TextEditingController(text: '40000001');
  final _passwordController = TextEditingController(text: '1234');
  bool _isRegister = false;
  bool _isLoading = false;
  String? _authMessage;

  String get _appLabel => switch (widget.destination) {
    LoginDestination.customerBanking => 'App Clientes',
    LoginDestination.salesForce => 'App Fuerza de Ventas',
  };

  IconData get _appIcon => switch (widget.destination) {
    LoginDestination.customerBanking => Icons.account_balance_wallet_outlined,
    LoginDestination.salesForce => Icons.route_outlined,
  };

  String get _defaultEmail => switch (widget.destination) {
    LoginDestination.customerBanking => '40000001',
    LoginDestination.salesForce => '0001',
  };

  String get _loginSubtitle => switch (widget.destination) {
    LoginDestination.customerBanking =>
      'Ingresa para consultar tus productos de banca movil.',
    LoginDestination.salesForce =>
      'Ingresa para gestionar tu cartera y solicitudes de credito.',
  };

  String get _registerSubtitle => switch (widget.destination) {
    LoginDestination.customerBanking =>
      'Registra tus datos para activar la banca movil.',
    LoginDestination.salesForce =>
      'Registra tus datos para activar el acceso de oficial de credito.',
  };

  bool get _isCustomer =>
      widget.destination == LoginDestination.customerBanking;

  Color get _heroColor =>
      _isCustomer ? InterbankTheme.blue : InterbankTheme.field;

  Color get _heroAccent =>
      _isCustomer ? InterbankTheme.green : InterbankTheme.copper;

  String get _heroTitle => _isCustomer
      ? 'Banca movil para tu dia'
      : 'Consola de campo para asesores';

  String get _heroSubtitle => _isCustomer
      ? 'Consulta saldos, paga servicios y revisa tus movimientos desde un flujo personal.'
      : 'Prioriza visitas, captura solicitudes y trabaja aun sin conexion.';

  List<_LoginMetric> get _heroMetrics => _isCustomer
      ? const [
          _LoginMetric('S/ 8,430', 'saldo demo'),
          _LoginMetric('3', 'pagos listos'),
          _LoginMetric('1', 'credito activo'),
        ]
      : const [
          _LoginMetric('3', 'visitas hoy'),
          _LoginMetric('2', 'expedientes'),
          _LoginMetric('online', 'API conectada'),
        ];

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: _defaultEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dniController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final AuthUser user;
      if (_isRegister) {
        user = await widget.dependencies.registerUser(
          RegisterRequest(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            dni: _dniController.text.trim(),
            password: _passwordController.text,
          ),
        );
      } else {
        user = await widget.dependencies.loginUser(
          LoginRequest(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            dni: _dniController.text.trim(),
          ),
        );
      }

      if (!_canEnterDestination(user)) {
        setState(() {
          _authMessage = widget.destination == LoginDestination.customerBanking
              ? 'Usa un usuario cliente para ingresar a banca movil.'
              : 'Usa un usuario asesor para ingresar a fuerza de ventas.';
        });
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => switch (widget.destination) {
            LoginDestination.customerBanking => CustomerShell(
              dependencies: widget.dependencies,
              user: user,
            ),
            LoginDestination.salesForce => SalesShell(
              dependencies: widget.dependencies,
              user: user,
            ),
          },
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _canEnterDestination(AuthUser user) {
    return switch (widget.destination) {
      LoginDestination.customerBanking => user.role == UserRole.customer,
      LoginDestination.salesForce => user.role == UserRole.salesOfficer,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isCustomer
                ? const [Color(0xFFF1FAFF), Color(0xFFEAF7EF)]
                : const [Color(0xFFF6F5EF), Color(0xFFEFF3EA)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final form = _LoginFormPanel(
                      appIcon: _appIcon,
                      appLabel: _appLabel,
                      isRegister: _isRegister,
                      isLoading: _isLoading,
                      authMessage: _authMessage,
                      loginSubtitle: _loginSubtitle,
                      registerSubtitle: _registerSubtitle,
                      formKey: _formKey,
                      nameController: _nameController,
                      emailController: _emailController,
                      dniController: _dniController,
                      passwordController: _passwordController,
                      destination: widget.destination,
                      onSubmit: _submit,
                      onToggleRegister: () => setState(() {
                        _isRegister = !_isRegister;
                        _authMessage = null;
                      }),
                    );
                    final hero = _LoginHeroPanel(
                      color: _heroColor,
                      accent: _heroAccent,
                      icon: _appIcon,
                      title: _heroTitle,
                      subtitle: _heroSubtitle,
                      metrics: _heroMetrics,
                      isCustomer: _isCustomer,
                    );

                    if (constraints.maxWidth >= 820) {
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 11, child: hero),
                            const SizedBox(width: 18),
                            Expanded(flex: 9, child: form),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [hero, const SizedBox(height: 18), form],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginFormPanel extends StatelessWidget {
  const _LoginFormPanel({
    required this.appIcon,
    required this.appLabel,
    required this.isRegister,
    required this.isLoading,
    required this.authMessage,
    required this.loginSubtitle,
    required this.registerSubtitle,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.dniController,
    required this.passwordController,
    required this.destination,
    required this.onSubmit,
    required this.onToggleRegister,
  });

  final IconData appIcon;
  final String appLabel;
  final bool isRegister;
  final bool isLoading;
  final String? authMessage;
  final String loginSubtitle;
  final String registerSubtitle;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController dniController;
  final TextEditingController passwordController;
  final LoginDestination destination;
  final VoidCallback onSubmit;
  final VoidCallback onToggleRegister;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE6EE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const InterbankLogo(),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: Icon(appIcon, size: 18),
              label: Text(appLabel),
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.08,
              ),
              side: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.18),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isRegister ? 'Crear cuenta' : 'Bienvenido',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            isRegister ? registerSubtitle : loginSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF526579),
            ),
          ),
          const SizedBox(height: 24),
          Form(
            key: formKey,
            child: Column(
              children: [
                if (isRegister) ...[
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) =>
                        Validators.requiredText(value, field: 'Nombre'),
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: destination == LoginDestination.salesForce
                        ? 'Codigo de empleado'
                        : 'DNI / Numero de documento',
                    prefixIcon: Icon(
                      destination == LoginDestination.salesForce
                          ? Icons.badge_outlined
                          : Icons.person_outline,
                    ),
                  ),
                  validator: (value) => Validators.requiredText(
                    value,
                    field: destination == LoginDestination.salesForce
                        ? 'Codigo de empleado'
                        : 'DNI',
                  ),
                ),
                const SizedBox(height: 14),
                if (isRegister) ...[
                  TextFormField(
                    controller: dniController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'DNI',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: Validators.dni,
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contrasena',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: Validators.password,
                ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : onSubmit,
                  icon: isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: Text(isRegister ? 'Registrarme' : 'Ingresar'),
                ),
                if (authMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    authMessage!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (destination == LoginDestination.customerBanking)
                  TextButton(
                    onPressed: isLoading ? null : onToggleRegister,
                    child: Text(
                      isRegister ? 'Ya tengo cuenta' : 'Crear una cuenta nueva',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginHeroPanel extends StatelessWidget {
  const _LoginHeroPanel({
    required this.color,
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.metrics,
    required this.isCustomer,
  });

  final Color color;
  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<_LoginMetric> metrics;
  final bool isCustomer;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 360),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0F172A),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                isCustomer ? 'Clientes' : 'Fuerza de Ventas',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 4,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 34,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 34),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: metrics.map((metric) {
              return Container(
                width: 132,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metric.label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LoginMetric {
  const _LoginMetric(this.value, this.label);

  final String value;
  final String label;
}
