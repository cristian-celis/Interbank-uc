class SalesPortfolioSnapshot {
  const SalesPortfolioSnapshot({
    required this.officerName,
    required this.dailyVisits,
    required this.activeApplications,
  });

  final String officerName;
  final List<CustomerVisit> dailyVisits;
  final List<CreditApplication> activeApplications;
}

class CustomerVisit {
  const CustomerVisit({
    required this.id,
    required this.customerName,
    required this.address,
    required this.visitTime,
    required this.reason,
    required this.creditFile,
  });

  final String id;
  final String customerName;
  final String address;
  final String visitTime;
  final String reason;
  final CustomerCreditFile creditFile;
}

class CustomerCreditFile {
  const CustomerCreditFile({
    required this.score,
    required this.riskLevel,
    required this.activeProducts,
    required this.paymentBehavior,
  });

  final int score;
  final String riskLevel;
  final List<String> activeProducts;
  final String paymentBehavior;
}

class CreditApplicationDraft {
  const CreditApplicationDraft({
    required this.officerId,
    required this.customerName,
    required this.dni,
    required this.phone,
    required this.amount,
    required this.businessActivity,
    required this.offlineCaptured,
    required this.documents,
  });

  final String officerId;
  final String customerName;
  final String dni;
  final String phone;
  final double amount;
  final String businessActivity;
  final bool offlineCaptured;
  final List<DocumentCapture> documents;
}

class DocumentCapture {
  const DocumentCapture({
    required this.type,
    required this.fileName,
    required this.captured,
  });

  final String type;
  final String fileName;
  final bool captured;
}

class BureauCheck {
  const BureauCheck({
    required this.provider,
    required this.result,
    required this.checkedAt,
  });

  final String provider;
  final String result;
  final DateTime checkedAt;
}

class CreditApplication {
  const CreditApplication({
    required this.id,
    required this.customerName,
    required this.amount,
    required this.status,
    required this.bureauCheck,
    required this.transmitted,
    this.createdAt,
  });

  final String id;
  final String customerName;
  final double amount;
  final ApplicationStatus status;
  final BureauCheck bureauCheck;
  final bool transmitted;
  final DateTime? createdAt;
}

enum ApplicationStatus { sent, underReview, approved, disbursed }

extension ApplicationStatusLabel on ApplicationStatus {
  String get label {
    return switch (this) {
      ApplicationStatus.sent => 'Enviado',
      ApplicationStatus.underReview => 'En evaluacion',
      ApplicationStatus.approved => 'Aprobado',
      ApplicationStatus.disbursed => 'Desembolsado',
    };
  }
}
