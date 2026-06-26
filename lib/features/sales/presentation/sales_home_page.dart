import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../app/theme/interbank_theme.dart';
import '../../../core/validation/validators.dart';
import '../../../shared/presentation/interbank_logo.dart';
import '../../auth/domain/entities/auth_user.dart';
import '../domain/entities/sales_portfolio.dart';

class SalesHomePage extends StatefulWidget {
  const SalesHomePage({
    super.key,
    required this.dependencies,
    required this.user,
  });

  final AppDependencies dependencies;
  final AuthUser user;

  @override
  State<SalesHomePage> createState() => _SalesHomePageState();
}

class _SalesHomePageState extends State<SalesHomePage> {
  late Future<SalesPortfolioSnapshot> _portfolioFuture;
  final _applicationKey = GlobalKey<FormState>();
  final _customerController = TextEditingController(text: 'Comercial Centro');
  final _dniController = TextEditingController(text: '70605040');
  final _phoneController = TextEditingController(text: '987654321');
  final _amountController = TextEditingController(text: '15000');
  final _activityController = TextEditingController(text: 'Venta minorista');
  CreditApplication? _lastApplication;
  Timer? _refreshTimer;
  int _selectedIndex = 0;
  bool _offlineFirst = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _portfolioFuture = widget.dependencies.getSalesPortfolio(widget.user.id);
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _submitting) return;
      setState(() {
        _portfolioFuture = widget.dependencies.getSalesPortfolio(widget.user.id);
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _customerController.dispose();
    _dniController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _activityController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_applicationKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final application = await widget.dependencies.submitCreditApplication(
        CreditApplicationDraft(
          officerId: widget.user.id,
          customerName: _customerController.text.trim(),
          dni: _dniController.text.trim(),
          phone: _phoneController.text.trim(),
          amount: double.parse(_amountController.text.replaceAll(',', '.')),
          businessActivity: _activityController.text.trim(),
          offlineCaptured: _offlineFirst,
          documents: const [
            DocumentCapture(
              type: 'DNI frontal',
              fileName: 'dni_frontal.jpg',
              captured: true,
            ),
            DocumentCapture(
              type: 'Documento legal',
              fileName: 'documento_legal.jpg',
              captured: true,
            ),
          ],
        ),
      );
      setState(() {
        _lastApplication = application;
        _portfolioFuture = widget.dependencies.getSalesPortfolio(
          widget.user.id,
        );
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _completeAssignedApplication(CreditApplication application) async {
    final incomeController = TextEditingController(text: (application.amount * 0.42).toStringAsFixed(2));
    final expensesController = TextEditingController(text: (application.amount * 0.14).toStringAsFixed(2));
    final assetsController = TextEditingController(text: (application.amount * 1.8).toStringAsFixed(2));
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Completar Solicitud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: incomeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ingresos mensuales'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: expensesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Gastos mensuales'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: assetsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Patrimonio estimado'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (result != true) return;

    await widget.dependencies.completeAssignedApplication(
      applicationId: application.id,
      income: double.parse(incomeController.text.replaceAll(',', '.')),
      expenses: double.parse(expensesController.text.replaceAll(',', '.')),
      assets: double.parse(assetsController.text.replaceAll(',', '.')),
      latitude: -12.0464,
      longitude: -77.0428,
    );
    setState(() {
      _portfolioFuture = widget.dependencies.getSalesPortfolio(widget.user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SalesPortfolioSnapshot>(
      future: _portfolioFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final portfolio = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: const InterbankLogo(compact: true, inverse: true),
            actions: [
              IconButton(
                tooltip: 'Actualizar cartera',
                onPressed: () => setState(() {
                  _portfolioFuture = widget.dependencies.getSalesPortfolio(
                    widget.user.id,
                  );
                }),
                icon: const Icon(Icons.refresh),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Chip(
                    avatar: const Icon(Icons.badge_outlined, size: 16),
                    label: const Text('Fuerza de Ventas'),
                    backgroundColor: InterbankTheme.lime,
                    side: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _PortfolioTab(portfolio: portfolio),
              _RouteTab(visits: portfolio.dailyVisits),
              _ApplicationTab(
                applications: portfolio.activeApplications.where((a) => a.status == ApplicationStatus.sent).toList(),
                onComplete: _completeAssignedApplication,
              ),
              _StatusTab(
                applications: portfolio.activeApplications,
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() {
              _selectedIndex = index;
            }),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.workspaces_outline),
                selectedIcon: Icon(Icons.workspaces),
                label: 'Cartera',
              ),
              NavigationDestination(
                icon: Icon(Icons.route_outlined),
                selectedIcon: Icon(Icons.route),
                label: 'Ruta',
              ),
              NavigationDestination(
                icon: Icon(Icons.note_add_outlined),
                selectedIcon: Icon(Icons.note_add),
                label: 'Solicitud',
              ),
              NavigationDestination(
                icon: Icon(Icons.timeline_outlined),
                selectedIcon: Icon(Icons.timeline),
                label: 'Estados',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SalesTabScaffold extends StatelessWidget {
  const _SalesTabScaffold({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: children,
    );
  }
}

class _PortfolioTab extends StatelessWidget {
  const _PortfolioTab({required this.portfolio});

  final SalesPortfolioSnapshot portfolio;

  @override
  Widget build(BuildContext context) {
    return _SalesTabScaffold(
      children: [
        _OfficerHeader(portfolio: portfolio),
        const SizedBox(height: 14),
        _SalesMetrics(portfolio: portfolio),
        const SizedBox(height: 22),
        const _SectionTitle(
          title: 'Cartera diaria',
          icon: Icons.groups_outlined,
        ),
        ...portfolio.dailyVisits.map(_VisitCard.new),
      ],
    );
  }
}

class _RouteTab extends StatelessWidget {
  const _RouteTab({required this.visits});

  final List<CustomerVisit> visits;

  @override
  Widget build(BuildContext context) {
    return _SalesTabScaffold(
      children: [
        const _SectionTitle(title: 'Ruta de hoy', icon: Icons.route_outlined),
        _RouteMapPanel(visits: visits),
        const SizedBox(height: 16),
        _RoutePlan(visits: visits),
      ],
    );
  }
}

class _ApplicationTab extends StatelessWidget {
  const _ApplicationTab({
    required this.applications,
    required this.onComplete,
  });

  final List<CreditApplication> applications;
  final Future<void> Function(CreditApplication) onComplete;

  @override
  Widget build(BuildContext context) {
    return _SalesTabScaffold(
      children: [
        const _SectionTitle(
          title: 'Solicitudes pendientes',
          icon: Icons.note_alt_outlined,
        ),
        if (applications.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No hay solicitudes pendientes de completar.'),
          ),
        ...applications.map(
          (application) => _ApplicationStatusCard(
            application,
            onComplete: () => onComplete(application),
          ),
        ),
      ],
    );
  }
}

class _StatusTab extends StatelessWidget {
  const _StatusTab({required this.applications});

  final List<CreditApplication> applications;

  @override
  Widget build(BuildContext context) {
    final completedApplications = applications.where((a) => a.status != ApplicationStatus.sent).toList();
    
    return _SalesTabScaffold(
      children: [
        const _SectionTitle(
          title: 'Estado de solicitudes',
          icon: Icons.timeline_outlined,
        ),
        _PipelineSummary(applications: applications),
        const SizedBox(height: 14),
        if (completedApplications.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No hay solicitudes procesadas por el comité.'),
          ),
        ...completedApplications.map(
          (application) => _ApplicationStatusCard(application),
        ),
      ],
    );
  }
}

class _OfficerHeader extends StatelessWidget {
  const _OfficerHeader({required this.portfolio});

  final SalesPortfolioSnapshot portfolio;

  @override
  Widget build(BuildContext context) {
    final nextVisit = portfolio.dailyVisits.isEmpty
        ? 'Sin visitas'
        : portfolio.dailyVisits.first.visitTime;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: InterbankTheme.field,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29102A26),
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
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                child: const Icon(
                  Icons.person_pin_circle_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      portfolio.officerName,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    Text(
                      'Siguiente visita $nextVisit',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.sync_outlined, color: InterbankTheme.lime),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _FieldBadge(
                icon: Icons.wifi_off_outlined,
                label: 'Offline listo',
              ),
              _FieldBadge(icon: Icons.location_on_outlined, label: 'Huancayo'),
              _FieldBadge(
                icon: Icons.lock_clock_outlined,
                label: 'Cierre 18:00',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SalesMetrics extends StatelessWidget {
  const _SalesMetrics({required this.portfolio});

  final SalesPortfolioSnapshot portfolio;

  @override
  Widget build(BuildContext context) {
    final approved = portfolio.activeApplications
        .where((item) => item.status == ApplicationStatus.approved)
        .length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 640
            ? (constraints.maxWidth - 20) / 3
            : constraints.maxWidth;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MetricCard(
              width: width,
              icon: Icons.groups_outlined,
              label: 'Visitas',
              value: '${portfolio.dailyVisits.length}',
            ),
            _MetricCard(
              width: width,
              icon: Icons.assignment_outlined,
              label: 'Solicitudes',
              value: '${portfolio.activeApplications.length}',
            ),
            _MetricCard(
              width: width,
              icon: Icons.verified_outlined,
              label: 'Aprobadas',
              value: '$approved',
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

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
              color: InterbankTheme.field.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: InterbankTheme.field, size: 20),
          ),
          const SizedBox(width: 10),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard(this.visit);

  final CustomerVisit visit;

  @override
  Widget build(BuildContext context) {
    final riskColor = _riskColor(visit.creditFile.riskLevel);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: InterbankTheme.field.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              visit.visitTime,
              style: const TextStyle(
                color: InterbankTheme.field,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ),
        title: Text(
          visit.customerName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          visit.reason,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _RiskChip(
          label: visit.creditFile.riskLevel,
          color: riskColor,
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              visit.address,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          _CreditFilePanel(file: visit.creditFile),
        ],
      ),
    );
  }
}

class _RouteMapPanel extends StatelessWidget {
  const _RouteMapPanel({required this.visits});

  final List<CustomerVisit> visits;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: InterbankTheme.field,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map_outlined, color: InterbankTheme.lime),
              const SizedBox(width: 8),
              Text(
                'Corredor Centro',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
              const Spacer(),
              Text(
                '${visits.length} paradas',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (index, visit) in visits.indexed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: InterbankTheme.lime,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: InterbankTheme.field,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        visit.visitTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutePlan extends StatelessWidget {
  const _RoutePlan({required this.visits});

  final List<CustomerVisit> visits;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final (index, visit) in visits.indexed)
              _RouteStop(
                index: index,
                visit: visit,
                isLast: index == visits.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationStatusCard extends StatelessWidget {
  const _ApplicationStatusCard(this.application, {this.onComplete});

  final CreditApplication application;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(application.status);
    final dateStr = application.createdAt != null
        ? '${application.createdAt!.day.toString().padLeft(2, '0')}/'
          '${application.createdAt!.month.toString().padLeft(2, '0')}/'
          '${application.createdAt!.year}'
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
              child: Icon(_statusIcon(application.status), color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    application.customerName,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    application.bureauCheck.result,
                    style: const TextStyle(color: Color(0xFF555555), fontSize: 12),
                  ),
                  if (dateStr.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Solicitud del $dateStr',
                      style: const TextStyle(color: Color(0xFF999999), fontSize: 11),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'S/ ${application.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (onComplete != null)
              FilledButton.tonal(
                onPressed: onComplete,
                child: const Text('Completar'),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  application.status.label,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: InterbankTheme.field),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF66706B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(fontSize: 24),
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

class _CreditFilePanel extends StatelessWidget {
  const _CreditFilePanel({required this.file});

  final CustomerCreditFile file;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7DEC7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DataPill(label: 'Score ${file.score}', icon: Icons.speed),
              _DataPill(
                label: 'Riesgo ${file.riskLevel}',
                icon: Icons.shield_outlined,
              ),
              _DataPill(
                label: file.paymentBehavior,
                icon: Icons.history_toggle_off,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Productos: ${file.activeProducts.join(', ')}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({
    required this.index,
    required this.visit,
    required this.isLast,
  });

  final int index;
  final CustomerVisit visit;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: InterbankTheme.field,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit.customerName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '${visit.visitTime} | ${visit.address}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF66706B)),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Navegar',
            onPressed: () {},
            icon: const Icon(Icons.navigation_outlined),
          ),
        ],
      ),
    );
  }
}

class _PipelineSummary extends StatelessWidget {
  const _PipelineSummary({required this.applications});

  final List<CreditApplication> applications;

  @override
  Widget build(BuildContext context) {
    final pendingSync = applications.where((item) => !item.transmitted).length;
    final totalAmount = applications.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 560
            ? (constraints.maxWidth - 10) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MetricCard(
              width: width,
              icon: Icons.payments_outlined,
              label: 'Monto en pipeline',
              value: _money(totalAmount),
            ),
            _MetricCard(
              width: width,
              icon: Icons.cloud_off_outlined,
              label: 'Pendientes sync',
              value: '$pendingSync',
            ),
          ],
        );
      },
    );
  }
}

class _CaptureNotice extends StatelessWidget {
  const _CaptureNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: InterbankTheme.sand,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFE4A8)),
      ),
      child: const Row(
        children: [
          Icon(Icons.assignment_ind_outlined, color: InterbankTheme.field),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Captura datos, documentos y validacion de buro antes de enviar.',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleSimulator extends StatelessWidget {
  const _ScheduleSimulator({required this.amountController});

  final TextEditingController amountController;

  @override
  Widget build(BuildContext context) {
    final amount =
        double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0;
    const months = 12;
    final monthlyRate = 0.32 / 12;
    final installment = amount <= 0
        ? 0.0
        : amount *
              (monthlyRate / (1 - (1 / _pow(1 + monthlyRate, months))));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Simulador de cronograma',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _SchedulePreviewRow(label: 'Plazo', value: '$months cuotas'),
          _SchedulePreviewRow(label: 'TEA referencial', value: '32.00%'),
          _SchedulePreviewRow(
            label: 'Cuota estimada',
            value: 'S/ ${installment.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  static double _pow(double base, int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}

class _SchedulePreviewRow extends StatelessWidget {
  const _SchedulePreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(children: [first, const SizedBox(height: 12), second]);
        }

        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _FieldBadge extends StatelessWidget {
  const _FieldBadge({required this.icon, required this.label});

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
          Icon(icon, color: InterbankTheme.lime, size: 17),
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

class _RiskChip extends StatelessWidget {
  const _RiskChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _DataPill extends StatelessWidget {
  const _DataPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE2D8BF)),
    );
  }
}

class _DocumentChip extends StatelessWidget {
  const _DocumentChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: InterbankTheme.field.withValues(alpha: 0.08),
      side: BorderSide(color: InterbankTheme.field.withValues(alpha: 0.18)),
    );
  }
}

Color _riskColor(String risk) {
  return switch (risk.toLowerCase()) {
    'bajo' => InterbankTheme.field,
    'medio' => const Color(0xFFD48A13),
    _ => const Color(0xFFE24C4C),
  };
}

Color _statusColor(ApplicationStatus status) {
  return switch (status) {
    ApplicationStatus.sent => const Color(0xFF2F6FED),
    ApplicationStatus.underReview => const Color(0xFFD48A13),
    ApplicationStatus.approved => InterbankTheme.field,
    ApplicationStatus.disbursed => InterbankTheme.green,
  };
}

IconData _statusIcon(ApplicationStatus status) {
  return switch (status) {
    ApplicationStatus.sent => Icons.outgoing_mail,
    ApplicationStatus.underReview => Icons.manage_search,
    ApplicationStatus.approved => Icons.verified_outlined,
    ApplicationStatus.disbursed => Icons.payments_outlined,
  };
}

String _money(double amount) => 'S/ ${amount.toStringAsFixed(2)}';
