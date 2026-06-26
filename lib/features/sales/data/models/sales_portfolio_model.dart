import '../../domain/entities/sales_portfolio.dart';

class SalesPortfolioSnapshotModel extends SalesPortfolioSnapshot {
  const SalesPortfolioSnapshotModel({
    required super.officerName,
    required super.dailyVisits,
    required super.activeApplications,
  });

  factory SalesPortfolioSnapshotModel.fromMap(Map<String, Object?> map) {
    return SalesPortfolioSnapshotModel(
      officerName: map['officerName'] as String,
      dailyVisits: (map['dailyVisits'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(CustomerVisitModel.fromMap)
          .toList(),
      activeApplications: (map['activeApplications'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(CreditApplicationModel.fromMap)
          .toList(),
    );
  }
}

class CustomerVisitModel extends CustomerVisit {
  const CustomerVisitModel({
    required super.id,
    required super.customerName,
    required super.address,
    required super.visitTime,
    required super.reason,
    required super.creditFile,
  });

  factory CustomerVisitModel.fromMap(Map<String, Object?> map) {
    return CustomerVisitModel(
      id: map['id'] as String,
      customerName: map['customerName'] as String,
      address: map['address'] as String,
      visitTime: map['visitTime'] as String,
      reason: map['reason'] as String,
      creditFile: CustomerCreditFileModel.fromMap(
        map['creditFile'] as Map<String, Object?>,
      ),
    );
  }
}

class CustomerCreditFileModel extends CustomerCreditFile {
  const CustomerCreditFileModel({
    required super.score,
    required super.riskLevel,
    required super.activeProducts,
    required super.paymentBehavior,
  });

  factory CustomerCreditFileModel.fromMap(Map<String, Object?> map) {
    return CustomerCreditFileModel(
      score: map['score'] as int,
      riskLevel: map['riskLevel'] as String,
      activeProducts: (map['activeProducts'] as List<Object?>).cast<String>(),
      paymentBehavior: map['paymentBehavior'] as String,
    );
  }
}

class CreditApplicationModel extends CreditApplication {
  const CreditApplicationModel({
    required super.id,
    required super.customerName,
    required super.amount,
    required super.status,
    required super.bureauCheck,
    required super.transmitted,
    super.createdAt,
  });

  factory CreditApplicationModel.fromMap(Map<String, Object?> map) {
    DateTime? createdAt;
    final rawDate = map['createdAt'] as String?;
    if (rawDate != null) {
      try { createdAt = DateTime.parse(rawDate); } catch (_) {}
    }
    return CreditApplicationModel(
      id: map['id'] as String,
      customerName: map['customerName'] as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      status: _status(map['status'] as String),
      bureauCheck: BureauCheckModel.fromMap(
        map['bureauCheck'] as Map<String, Object?>,
      ),
      transmitted: map['transmitted'] as bool,
      createdAt: createdAt,
    );
  }

  static ApplicationStatus _status(String value) {
    return ApplicationStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ApplicationStatus.sent,
    );
  }
}

class BureauCheckModel extends BureauCheck {
  const BureauCheckModel({
    required super.provider,
    required super.result,
    required super.checkedAt,
  });

  factory BureauCheckModel.fromMap(Map<String, Object?> map) {
    return BureauCheckModel(
      provider: map['provider'] as String,
      result: map['result'] as String,
      checkedAt: DateTime.parse(map['checkedAt'] as String),
    );
  }
}
