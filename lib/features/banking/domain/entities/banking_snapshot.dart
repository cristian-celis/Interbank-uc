class CustomerBankingSnapshot {
  const CustomerBankingSnapshot({
    required this.customerName,
    required this.totalBalance,
    required this.savingsAccounts,
    required this.movements,
    required this.credits,
    required this.paymentServices,
    required this.loanRequests,
  });

  final String customerName;
  final double totalBalance;
  final List<SavingsAccount> savingsAccounts;
  final List<BankMovement> movements;
  final List<CreditLoan> credits;
  final List<PaymentService> paymentServices;
  final List<CustomerLoanRequest> loanRequests;
}

class CustomerLoanRequest {
  const CustomerLoanRequest({
    required this.id,
    required this.expedient,
    required this.amount,
    required this.approvedAmount,
    required this.termMonths,
    required this.purpose,
    required this.status,
    required this.rejectionReason,
    required this.advisorName,
    this.createdAt,
  });

  final String id;
  final String expedient;
  final double amount;
  final double approvedAmount;
  final int termMonths;
  final String purpose;
  final String status;
  final String? rejectionReason;
  final String advisorName;
  final DateTime? createdAt;

  /// Devuelve el estado en español para mostrarlo al usuario
  String get statusLabel => switch (status) {
    'borrador' => 'Pendiente de revisión',
    'enviado' => 'Enviado al comité',
    'recibido_comite' => 'En evaluación',
    'en_evaluacion' => 'En evaluación',
    'aprobada' => 'Aprobado ✓',
    'rechazado' => 'Rechazado',
    'desembolsada' => 'Desembolsado',
    _ => status,
  };
}

class SavingsAccount {
  const SavingsAccount({
    required this.id,
    required this.name,
    required this.currency,
    required this.balance,
    required this.accountNumber,
    required this.lastStatementPeriod,
  });

  final String id;
  final String name;
  final String currency;
  final double balance;
  final String accountNumber;
  final String lastStatementPeriod;
}

class BankMovement {
  const BankMovement({
    required this.description,
    required this.date,
    required this.amount,
    required this.type,
  });

  final String description;
  final DateTime date;
  final double amount;
  final MovementType type;
}

enum MovementType { deposit, withdrawal, payment, transfer }

class CreditLoan {
  const CreditLoan({
    required this.id,
    required this.productName,
    required this.principal,
    required this.outstandingBalance,
    required this.nextPaymentDate,
    required this.schedule,
  });

  final String id;
  final String productName;
  final double principal;
  final double outstandingBalance;
  final DateTime nextPaymentDate;
  final List<PaymentScheduleItem> schedule;
}

class PaymentScheduleItem {
  const PaymentScheduleItem({
    required this.installment,
    required this.dueDate,
    required this.amount,
    required this.paid,
  });

  final int installment;
  final DateTime dueDate;
  final double amount;
  final bool paid;
}

class PaymentService {
  const PaymentService({
    required this.name,
    required this.category,
    required this.amount,
  });

  final String name;
  final String category;
  final double amount;
}
