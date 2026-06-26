import '../../domain/entities/banking_snapshot.dart';

class CustomerBankingSnapshotModel extends CustomerBankingSnapshot {
  const CustomerBankingSnapshotModel({
    required super.customerName,
    required super.totalBalance,
    required super.savingsAccounts,
    required super.movements,
    required super.credits,
    required super.paymentServices,
    required super.loanRequests,
  });

  factory CustomerBankingSnapshotModel.fromMap(Map<String, Object?> map) {
    return CustomerBankingSnapshotModel(
      customerName: map['customerName'] as String,
      totalBalance: map['totalBalance'] as double,
      savingsAccounts: (map['savingsAccounts'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(SavingsAccountModel.fromMap)
          .toList(),
      movements: (map['movements'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(BankMovementModel.fromMap)
          .toList(),
      credits: (map['credits'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(CreditLoanModel.fromMap)
          .toList(),
      paymentServices: (map['paymentServices'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(PaymentServiceModel.fromMap)
          .toList(),
      loanRequests: (map['loanRequests'] as List<Object?>? ?? const [])
          .cast<Map<String, Object?>>()
          .map(CustomerLoanRequestModel.fromMap)
          .toList(),
    );
  }
}

class CustomerLoanRequestModel extends CustomerLoanRequest {
  const CustomerLoanRequestModel({
    required super.id,
    required super.expedient,
    required super.amount,
    required super.approvedAmount,
    required super.termMonths,
    required super.purpose,
    required super.status,
    required super.rejectionReason,
    required super.advisorName,
    super.createdAt,
  });

  factory CustomerLoanRequestModel.fromMap(Map<String, Object?> map) {
    DateTime? createdAt;
    final rawDate = map['createdAt'] as String?;
    if (rawDate != null) {
      try { createdAt = DateTime.parse(rawDate); } catch (_) {}
    }
    return CustomerLoanRequestModel(
      id: map['id'] as String,
      expedient: map['expedient'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      approvedAmount: (map['approvedAmount'] as num?)?.toDouble() ?? 0,
      termMonths: map['termMonths'] as int? ?? 0,
      purpose: map['purpose'] as String? ?? '',
      status: map['status'] as String,
      rejectionReason: map['rejectionReason'] as String?,
      advisorName: map['advisorName'] as String? ?? '',
      createdAt: createdAt,
    );
  }
}

class SavingsAccountModel extends SavingsAccount {
  const SavingsAccountModel({
    required super.id,
    required super.name,
    required super.currency,
    required super.balance,
    required super.accountNumber,
    required super.lastStatementPeriod,
  });

  factory SavingsAccountModel.fromMap(Map<String, Object?> map) {
    return SavingsAccountModel(
      id: map['id'] as String,
      name: map['name'] as String,
      currency: map['currency'] as String,
      balance: map['balance'] as double,
      accountNumber: map['accountNumber'] as String,
      lastStatementPeriod: map['lastStatementPeriod'] as String,
    );
  }
}

class BankMovementModel extends BankMovement {
  const BankMovementModel({
    required super.description,
    required super.date,
    required super.amount,
    required super.type,
  });

  factory BankMovementModel.fromMap(Map<String, Object?> map) {
    return BankMovementModel(
      description: map['description'] as String,
      date: DateTime.parse(map['date'] as String),
      amount: map['amount'] as double,
      type: _movementType(map['type'] as String),
    );
  }

  static MovementType _movementType(String value) {
    return MovementType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => MovementType.transfer,
    );
  }
}

class CreditLoanModel extends CreditLoan {
  const CreditLoanModel({
    required super.id,
    required super.productName,
    required super.principal,
    required super.outstandingBalance,
    required super.nextPaymentDate,
    required super.schedule,
  });

  factory CreditLoanModel.fromMap(Map<String, Object?> map) {
    return CreditLoanModel(
      id: map['id'] as String,
      productName: map['productName'] as String,
      principal: map['principal'] as double,
      outstandingBalance: map['outstandingBalance'] as double,
      nextPaymentDate: DateTime.parse(map['nextPaymentDate'] as String),
      schedule: (map['schedule'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(PaymentScheduleItemModel.fromMap)
          .toList(),
    );
  }
}

class PaymentScheduleItemModel extends PaymentScheduleItem {
  const PaymentScheduleItemModel({
    required super.installment,
    required super.dueDate,
    required super.amount,
    required super.paid,
  });

  factory PaymentScheduleItemModel.fromMap(Map<String, Object?> map) {
    return PaymentScheduleItemModel(
      installment: map['installment'] as int,
      dueDate: DateTime.parse(map['dueDate'] as String),
      amount: map['amount'] as double,
      paid: map['paid'] as bool,
    );
  }
}

class PaymentServiceModel extends PaymentService {
  const PaymentServiceModel({
    required super.name,
    required super.category,
    required super.amount,
  });

  factory PaymentServiceModel.fromMap(Map<String, Object?> map) {
    return PaymentServiceModel(
      name: map['name'] as String,
      category: map['category'] as String,
      amount: map['amount'] as double,
    );
  }
}
