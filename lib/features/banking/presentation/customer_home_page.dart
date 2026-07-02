import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../app/theme/interbank_theme.dart';
import '../../../core/business/credit_policy.dart';
import '../../../core/validation/validators.dart';
import '../../../shared/presentation/interbank_logo.dart';
import '../../auth/domain/entities/auth_user.dart';
import '../domain/entities/banking_snapshot.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({
    super.key,
    required this.dependencies,
    required this.user,
  });

  final AppDependencies dependencies;
  final AuthUser user;

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  late Future<CustomerBankingSnapshot> _snapshotFuture;
  final _transferKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();
  final _amountController = TextEditingController();
  final _loanAmountController = TextEditingController(text: '12000');
  final _loanIncomeController = TextEditingController(text: '5000');
  final _loanBusinessController = TextEditingController(
    text: 'Bodega familiar',
  );
  final _loanPurposeController = TextEditingController(
    text: 'Capital de trabajo',
  );
  int _selectedIndex = 0;
  String? _transferMessage;
  String? _loanMessage;
  bool _submittingOperation = false;
  bool _submittingLoan = false;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = widget.dependencies.getCustomerBankingSnapshot(
      widget.user.id,
    );
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _amountController.dispose();
    _loanAmountController.dispose();
    _loanIncomeController.dispose();
    _loanBusinessController.dispose();
    _loanPurposeController.dispose();
    super.dispose();
  }

  Future<void> _submitLoanRequest() async {
    final amount = double.parse(_loanAmountController.text);
    final policy = CreditPolicies.infer(
      purpose: _loanPurposeController.text,
      businessType: 'comercio',
    );
    final validationError =
        policy.validateAmount(amount) ??
        policy.validateTerm(12) ??
        policy.validateTea(policy.defaultTea);
    if (validationError != null) {
      setState(() => _loanMessage = validationError);
      return;
    }

    setState(() => _submittingLoan = true);
    try {
      await widget.dependencies.createCustomerLoanRequest(
        amount: amount,
        termMonths: 12,
        purpose: _loanPurposeController.text.trim(),
        businessType: 'comercio',
        businessName: _loanBusinessController.text.trim(),
        income: double.parse(_loanIncomeController.text),
      );
      setState(() {
        _loanMessage = 'Solicitud creada y asignada a un vendedor.';
        _snapshotFuture = widget.dependencies.getCustomerBankingSnapshot(
          widget.user.id,
        );
      });
    } finally {
      if (mounted) setState(() => _submittingLoan = false);
    }
  }

  void _refresh() {
    setState(() {
      _snapshotFuture = widget.dependencies.getCustomerBankingSnapshot(
        widget.user.id,
      );
    });
  }

  Future<void> _submitOperation(CustomerBankingSnapshot snapshot) async {
    if (!_transferKey.currentState!.validate()) return;
    if (snapshot.savingsAccounts.isEmpty) {
      setState(() => _transferMessage = 'No hay cuenta origen disponible.');
      return;
    }

    setState(() => _submittingOperation = true);
    try {
      final destination = _destinationController.text.trim();
      await widget.dependencies.createCustomerOperation(
        originAccount: snapshot.savingsAccounts.first.accountNumber,
        destinationAccount: destination.isEmpty ? null : destination,
        type: destination.toLowerCase().contains('tarjeta')
            ? 'pago_cuota'
            : 'transferencia',
        amount: double.parse(_amountController.text.replaceAll(',', '.')),
      );
      setState(() {
        _transferMessage = 'Operacion registrada en Core Mobile.';
        _snapshotFuture = widget.dependencies.getCustomerBankingSnapshot(
          widget.user.id,
        );
      });
    } finally {
      if (mounted) setState(() => _submittingOperation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CustomerBankingSnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: const InterbankLogo(compact: true),
            actions: [
              IconButton(
                tooltip: 'Actualizar datos',
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Notificaciones',
                onPressed: () => setState(() => _selectedIndex = 4),
                icon: const Icon(Icons.notifications_none_outlined),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Chip(
                    avatar: const Icon(Icons.phone_iphone, size: 16),
                    label: const Text('Clientes'),
                    backgroundColor: InterbankTheme.sky,
                    side: const BorderSide(color: Color(0xFFCDE9FF)),
                  ),
                ),
              ),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _DashboardTab(snapshot: data),
              _SavingsTab(snapshot: data),
              _CreditsTab(snapshot: data),
              _PaymentsTab(
                services: data.paymentServices,
                transferKey: _transferKey,
                destinationController: _destinationController,
                amountController: _amountController,
                transferMessage: _transferMessage,
                submitting: _submittingOperation,
                onValidate: () => _submitOperation(data),
              ),
              _CardsNotificationsTab(snapshot: data),
              _LoanRequestsTab(
                snapshot: data,
                amountController: _loanAmountController,
                incomeController: _loanIncomeController,
                businessController: _loanBusinessController,
                purposeController: _loanPurposeController,
                submitting: _submittingLoan,
                message: _loanMessage,
                onSubmit: _submitLoanRequest,
              ),
              _ProfileTab(user: widget.user, snapshot: data),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() {
              _selectedIndex = index;
            }),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: 'Cuentas',
              ),
              NavigationDestination(
                icon: Icon(Icons.credit_score_outlined),
                selectedIcon: Icon(Icons.credit_score),
                label: 'Creditos',
              ),
              NavigationDestination(
                icon: Icon(Icons.payments_outlined),
                selectedIcon: Icon(Icons.payments),
                label: 'Pagar',
              ),
              NavigationDestination(
                icon: Icon(Icons.credit_card_outlined),
                selectedIcon: Icon(Icons.credit_card),
                label: 'Tarjetas',
              ),
              NavigationDestination(
                icon: Icon(Icons.request_quote_outlined),
                selectedIcon: Icon(Icons.request_quote),
                label: 'Prestamo',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabScaffold extends StatelessWidget {
  const _TabScaffold({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: children,
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({required this.snapshot});

  final CustomerBankingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      children: [
        _BalanceHeader(snapshot: snapshot),
        const SizedBox(height: 14),
        const _QuickActionStrip(),
        const SizedBox(height: 22),
        const _SectionTitle(
          title: 'Ultimos movimientos',
          icon: Icons.receipt_long_outlined,
        ),
        ...snapshot.movements.map(_MovementTile.new),
      ],
    );
  }
}

class _SavingsTab extends StatelessWidget {
  const _SavingsTab({required this.snapshot});

  final CustomerBankingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      children: [
        _SectionTitle(
          title: 'Tus cuentas',
          icon: Icons.account_balance_wallet_outlined,
          helper: '${snapshot.savingsAccounts.length} activas',
        ),
        _SavingsOverview(snapshot: snapshot),
        const SizedBox(height: 14),
        ...snapshot.savingsAccounts.map(_SavingsCard.new),
        const SizedBox(height: 22),
        const _SectionTitle(
          title: 'Depositos recientes',
          icon: Icons.trending_up_outlined,
        ),
        ...snapshot.movements
            .where((movement) => movement.amount >= 0)
            .map(_MovementTile.new),
      ],
    );
  }
}

class _CreditsTab extends StatelessWidget {
  const _CreditsTab({required this.snapshot});

  final CustomerBankingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      children: [
        _SectionTitle(
          title: 'Prestamos activos',
          icon: Icons.credit_score_outlined,
          helper: '${snapshot.credits.length} producto',
        ),
        if (snapshot.credits.isEmpty)
          const _EmptyState(
            icon: Icons.info_outline,
            title: 'Sin creditos activos',
            subtitle: 'No hay prestamos vigentes para este cliente.',
          )
        else
          ...snapshot.credits.map(_CreditCard.new),
      ],
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab({
    required this.services,
    required this.transferKey,
    required this.destinationController,
    required this.amountController,
    required this.transferMessage,
    required this.submitting,
    required this.onValidate,
  });

  final List<PaymentService> services;
  final GlobalKey<FormState> transferKey;
  final TextEditingController destinationController;
  final TextEditingController amountController;
  final String? transferMessage;
  final bool submitting;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      children: [
        const _SectionTitle(
          title: 'Transferencias y pagos',
          icon: Icons.swap_horiz,
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: transferKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: destinationController,
                    decoration: const InputDecoration(
                      labelText: 'Cuenta o servicio destino',
                      prefixIcon: Icon(Icons.send_outlined),
                    ),
                    validator: (value) =>
                        Validators.requiredText(value, field: 'Destino'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    validator: Validators.amount,
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: submitting ? null : onValidate,
                    icon: submitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified_outlined),
                    label: const Text('Registrar operacion'),
                  ),
                  if (transferMessage != null) ...[
                    const SizedBox(height: 10),
                    _SuccessBanner(message: transferMessage!),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const _SectionTitle(
          title: 'Servicios frecuentes',
          icon: Icons.bolt_outlined,
        ),
        ...services.map(
          (service) => _PaymentServiceTile(
            service: service,
            onPressed: () {
              destinationController.text = service.name;
              amountController.text = service.amount.toStringAsFixed(2);
            },
          ),
        ),
      ],
    );
  }
}

class _CardsNotificationsTab extends StatelessWidget {
  const _CardsNotificationsTab({required this.snapshot});

  final CustomerBankingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final cards = snapshot.paymentServices
        .where((item) => item.name.startsWith('Tarjeta'))
        .toList();
    final notifications = snapshot.paymentServices
        .where((item) => !item.name.startsWith('Tarjeta'))
        .toList();

    return _TabScaffold(
      children: [
        _SectionTitle(
          title: 'Tarjetas',
          icon: Icons.credit_card_outlined,
          helper: '${cards.length} activas',
        ),
        if (cards.isEmpty)
          const _EmptyState(
            icon: Icons.credit_card_off_outlined,
            title: 'Sin tarjetas registradas',
            subtitle: 'No hay tarjetas vigentes para este cliente.',
          )
        else
          ...cards.map(_CardSummaryTile.new),
        const SizedBox(height: 22),
        _SectionTitle(
          title: 'Notificaciones',
          icon: Icons.notifications_none_outlined,
          helper: '${notifications.length} recientes',
        ),
        if (notifications.isEmpty)
          const _EmptyState(
            icon: Icons.notifications_off_outlined,
            title: 'Sin notificaciones',
            subtitle: 'No hay avisos pendientes.',
          )
        else
          ...notifications.map(_NotificationTile.new),
      ],
    );
  }
}

class _LoanRequestsTab extends StatelessWidget {
  const _LoanRequestsTab({
    required this.snapshot,
    required this.amountController,
    required this.incomeController,
    required this.businessController,
    required this.purposeController,
    required this.submitting,
    required this.message,
    required this.onSubmit,
  });

  final CustomerBankingSnapshot snapshot;
  final TextEditingController amountController;
  final TextEditingController incomeController;
  final TextEditingController businessController;
  final TextEditingController purposeController;
  final bool submitting;
  final String? message;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      children: [
        const _SectionTitle(
          title: 'Solicitar prestamo',
          icon: Icons.request_quote_outlined,
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monto solicitado',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: incomeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Ingreso mensual',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: businessController,
                  decoration: const InputDecoration(labelText: 'Negocio'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: purposeController,
                  decoration: const InputDecoration(
                    labelText: 'Destino del credito',
                  ),
                ),
                const SizedBox(height: 14),
                const _PolicyNotice(),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: submitting ? null : onSubmit,
                  icon: const Icon(Icons.send_outlined),
                  label: Text(submitting ? 'Enviando...' : 'Crear solicitud'),
                ),
                if (message != null) ...[
                  const SizedBox(height: 10),
                  _SuccessBanner(message: message!),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _SectionTitle(
          title: 'Mis solicitudes',
          icon: Icons.timeline_outlined,
          helper: '${snapshot.loanRequests.length}',
        ),
        if (snapshot.loanRequests.isEmpty)
          const _EmptyState(
            icon: Icons.inbox_outlined,
            title: 'Sin solicitudes',
            subtitle: 'Tus solicitudes apareceran aqui.',
          )
        else
          ...snapshot.loanRequests.map(_LoanRequestTile.new),
      ],
    );
  }
}

class _PolicyNotice extends StatelessWidget {
  const _PolicyNotice();

  @override
  Widget build(BuildContext context) {
    const policy = CreditPolicies.businessWorkingCapital;
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'TEA referencial ${policy.defaultTea.toStringAsFixed(2)}% '
        '(${policy.minTea.toStringAsFixed(2)}%-${policy.maxTea.toStringAsFixed(2)}%). '
        'Fuente: ${policy.source}.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF64748B),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LoanRequestTile extends StatelessWidget {
  const _LoanRequestTile(this.request);

  final CustomerLoanRequest request;

  Color _statusColor() => switch (request.status) {
    'aprobada' => const Color(0xFF2E7D32),
    'rechazado' => const Color(0xFFC62828),
    'recibido_comite' || 'en_evaluacion' => const Color(0xFF1565C0),
    _ => const Color(0xFF6A6A6A),
  };

  @override
  Widget build(BuildContext context) {
    final finalAmount = request.approvedAmount > 0
        ? request.approvedAmount
        : request.amount;
    final color = _statusColor();
    final dateStr = request.createdAt != null
        ? '${request.createdAt!.day.toString().padLeft(2, '0')}/'
              '${request.createdAt!.month.toString().padLeft(2, '0')}/'
              '${request.createdAt!.year}'
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(Icons.request_quote_outlined, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.expedient,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    request.purpose.isNotEmpty
                        ? request.purpose
                        : 'Sin destino especificado',
                    style: const TextStyle(
                      color: Color(0xFF555555),
                      fontSize: 12,
                    ),
                  ),
                  if (dateStr.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Creado el $dateStr',
                      style: const TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      request.statusLabel,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'S/ ${finalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                if (request.advisorName.isNotEmpty)
                  Text(
                    request.advisorName.split(' ').first,
                    style: const TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.user, required this.snapshot});

  final AuthUser user;
  final CustomerBankingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      children: [
        _ProfileHeader(user: user),
        const SizedBox(height: 18),
        const _SectionTitle(title: 'Resumen bancario', icon: Icons.insights),
        _SummaryPanel(
          items: [
            _SummaryItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Patrimonio',
              value: 'S/ ${snapshot.totalBalance.toStringAsFixed(2)}',
            ),
            _SummaryItem(
              icon: Icons.savings_outlined,
              label: 'Cuentas',
              value: '${snapshot.savingsAccounts.length}',
            ),
            _SummaryItem(
              icon: Icons.credit_score_outlined,
              label: 'Creditos',
              value: '${snapshot.credits.length}',
            ),
          ],
        ),
      ],
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.snapshot});

  final CustomerBankingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [InterbankTheme.blue, Color(0xFF007E68)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F003A70),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Saldo disponible',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.visibility_outlined,
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'S/ ${snapshot.totalBalance.toStringAsFixed(2)}',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontSize: 34,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            snapshot.customerName,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderPill(
                icon: Icons.account_balance_wallet_outlined,
                label: '${snapshot.savingsAccounts.length} cuentas',
              ),
              _HeaderPill(
                icon: Icons.credit_score_outlined,
                label: snapshot.credits.isEmpty
                    ? 'sin creditos'
                    : 'credito al dia',
              ),
              const _HeaderPill(
                icon: Icons.security_outlined,
                label: 'token activo',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionStrip extends StatelessWidget {
  const _QuickActionStrip();

  @override
  Widget build(BuildContext context) {
    const actions = [
      _QuickAction(Icons.swap_horiz, 'Transferir'),
      _QuickAction(Icons.qr_code_scanner_outlined, 'Pagar QR'),
      _QuickAction(Icons.receipt_long_outlined, 'Servicios'),
      _QuickAction(Icons.savings_outlined, 'Metas'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth >= 640
            ? (constraints.maxWidth - 30) / 4
            : (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: actions
              .map(
                (action) =>
                    _QuickActionButton(action: action, width: itemWidth),
              )
              .toList(),
        );
      },
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action, required this.width});

  final _QuickAction action;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(action.icon, color: scheme.secondary),
                const SizedBox(height: 10),
                Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon, this.helper});

  final String title;
  final IconData icon;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (helper != null)
            Text(
              helper!,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile(this.movement);

  final BankMovement movement;

  @override
  Widget build(BuildContext context) {
    final isPositive = movement.amount >= 0;
    final color = isPositive ? InterbankTheme.green : const Color(0xFFE24C4C);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(
            isPositive ? Icons.south_west : Icons.north_east,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          movement.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(_dateLabel(movement.date)),
        trailing: Text(
          '${isPositive ? '+' : '-'}S/ ${movement.amount.abs().toStringAsFixed(2)}',
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _SavingsOverview extends StatelessWidget {
  const _SavingsOverview({required this.snapshot});

  final CustomerBankingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final highest = snapshot.savingsAccounts.fold<double>(
      0,
      (value, account) => account.balance > value ? account.balance : value,
    );
    return _SummaryPanel(
      items: [
        _SummaryItem(
          icon: Icons.trending_up_outlined,
          label: 'Mayor saldo',
          value: 'S/ ${highest.toStringAsFixed(2)}',
        ),
        _SummaryItem(
          icon: Icons.description_outlined,
          label: 'Estado',
          value: snapshot.savingsAccounts.first.lastStatementPeriod,
        ),
      ],
    );
  }
}

class _SavingsCard extends StatelessWidget {
  const _SavingsCard(this.account);

  final SavingsAccount account;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: InterbankTheme.sky,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: InterbankTheme.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        account.accountNumber,
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${account.currency} ${account.balance.toStringAsFixed(2)}',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontSize: 26),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.file_download_done_outlined,
                  size: 18,
                  color: InterbankTheme.green,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Estado de cuenta: ${account.lastStatementPeriod}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditCard extends StatelessWidget {
  const _CreditCard(this.credit);

  final CreditLoan credit;

  @override
  Widget build(BuildContext context) {
    final paid = credit.schedule.where((item) => item.paid).length;
    final progress = credit.schedule.isEmpty
        ? 0.0
        : paid / credit.schedule.length;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    credit.productName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text('${(progress * 100).round()}% pagado'),
                  backgroundColor: InterbankTheme.sky,
                  side: BorderSide.none,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Saldo pendiente',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.54),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'S/ ${credit.outstandingBalance.toStringAsFixed(2)}',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: const Color(0xFFE2E8F0),
              color: InterbankTheme.green,
            ),
            const SizedBox(height: 14),
            _NextPaymentRow(credit: credit),
            const Divider(height: 28),
            ...credit.schedule.map(_ScheduleTile.new),
          ],
        ),
      ),
    );
  }
}

class _NextPaymentRow extends StatelessWidget {
  const _NextPaymentRow({required this.credit});

  final CreditLoan credit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFE5B3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_outlined, color: Color(0xFFD48A13)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Proximo pago ${_dateLabel(credit.nextPaymentDate)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile(this.item);

  final PaymentScheduleItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        item.paid ? Icons.check_circle : Icons.schedule,
        color: item.paid ? InterbankTheme.green : const Color(0xFFD48A13),
      ),
      title: Text('Cuota ${item.installment}'),
      subtitle: Text(_dateLabel(item.dueDate)),
      trailing: Text(
        'S/ ${item.amount.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _PaymentServiceTile extends StatelessWidget {
  const _PaymentServiceTile({required this.service, required this.onPressed});

  final PaymentService service;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: InterbankTheme.green.withValues(alpha: 0.1),
          child: const Icon(Icons.bolt_outlined, color: InterbankTheme.green),
        ),
        title: Text(service.name),
        subtitle: Text(service.category),
        trailing: FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: const Icon(Icons.add, size: 18),
          label: Text('S/ ${service.amount.toStringAsFixed(2)}'),
        ),
      ),
    );
  }
}

class _CardSummaryTile extends StatelessWidget {
  const _CardSummaryTile(this.card);

  final PaymentService card;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: InterbankTheme.blue.withValues(alpha: 0.1),
          child: const Icon(Icons.credit_card, color: InterbankTheme.blue),
        ),
        title: Text(card.name),
        subtitle: Text('${card.category} | saldo utilizado'),
        trailing: Text(
          'S/ ${card.amount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile(this.notification);

  final PaymentService notification;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: InterbankTheme.lime.withValues(alpha: 0.24),
          child: const Icon(
            Icons.notifications_none,
            color: InterbankTheme.green,
          ),
        ),
        title: Text(notification.name),
        subtitle: Text(notification.category),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: InterbankTheme.blue.withValues(alpha: 0.1),
            child: const Icon(Icons.person, color: InterbankTheme.blue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.email} | DNI ${user.dni}',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_user_outlined, color: InterbankTheme.green),
        ],
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.items});

  final List<_SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? items.length : 1;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - (10 * (columns - 1))) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map((item) => _SummaryTile(item: item, width: width))
              .toList(),
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.item, required this.width});

  final _SummaryItem item;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(item.icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: InterbankTheme.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: InterbankTheme.green.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: InterbankTheme.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: InterbankTheme.green,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _SummaryItem {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

String _dateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
