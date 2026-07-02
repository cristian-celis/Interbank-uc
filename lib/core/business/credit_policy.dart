import 'dart:math' as math;

class CreditPolicy {
  const CreditPolicy({
    required this.product,
    required this.minAmount,
    required this.maxAmount,
    required this.minTermMonths,
    required this.maxTermMonths,
    required this.minTea,
    required this.maxTea,
    required this.defaultTea,
    required this.source,
  });

  final String product;
  final double minAmount;
  final double maxAmount;
  final int minTermMonths;
  final int maxTermMonths;
  final double minTea;
  final double maxTea;
  final double defaultTea;
  final String source;

  String? validateAmount(double amount) {
    if (amount < minAmount || amount > maxAmount) {
      return '$product permite montos entre S/ ${minAmount.toStringAsFixed(0)} '
          'y S/ ${maxAmount.toStringAsFixed(0)}.';
    }
    return null;
  }

  String? validateTerm(int termMonths) {
    if (termMonths < minTermMonths || termMonths > maxTermMonths) {
      return '$product permite plazos entre $minTermMonths y $maxTermMonths meses.';
    }
    return null;
  }

  String? validateTea(double tea) {
    if (tea < minTea || tea > maxTea) {
      return '$product permite TEA entre ${minTea.toStringAsFixed(2)}% '
          'y ${maxTea.toStringAsFixed(2)}%.';
    }
    return null;
  }
}

class CreditPolicies {
  static const personalLoan = CreditPolicy(
    product: 'Prestamo personal',
    minAmount: 1000,
    maxAmount: 60000,
    minTermMonths: 6,
    maxTermMonths: 60,
    minTea: 8.99,
    maxTea: 99.90,
    defaultTea: 32.0,
    source: 'Interbank TAR-0242, consultado 02/07/2026',
  );

  static const businessWorkingCapital = CreditPolicy(
    product: 'Credito Banca Negocios / PYME',
    minAmount: 1,
    maxAmount: 1000000,
    minTermMonths: 1,
    maxTermMonths: 24,
    minTea: 29.65,
    maxTea: 55.00,
    defaultTea: 32.0,
    source: 'Interbank TAR-0244, TNA convertida a TEA, consultado 02/07/2026',
  );

  static CreditPolicy infer({String? purpose, String? businessType}) {
    final normalizedPurpose = (purpose ?? '').toLowerCase();
    final normalizedBusiness = (businessType ?? '').toLowerCase();
    if (normalizedBusiness.isNotEmpty ||
        normalizedPurpose.contains('capital') ||
        normalizedPurpose.contains('negocio') ||
        normalizedPurpose.contains('pyme')) {
      return businessWorkingCapital;
    }
    return personalLoan;
  }

  static double effectiveMonthlyRate(double tea) {
    return math.pow(1 + tea / 100, 1 / 12).toDouble() - 1;
  }

  static double frenchInstallment({
    required double amount,
    required int termMonths,
    required double tea,
  }) {
    final monthlyRate = effectiveMonthlyRate(tea);
    if (monthlyRate == 0) return amount / termMonths;
    return amount * monthlyRate / (1 - math.pow(1 + monthlyRate, -termMonths));
  }
}
