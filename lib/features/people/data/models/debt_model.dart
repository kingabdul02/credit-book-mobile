import 'transaction_model.dart';

// Domain Entity
class DebtEntity {
  final String id;
  final String transactionType; // 'they_owe_me' or 'i_owe_them'
  final double originalAmount;
  final double paidAmount;
  final double outstandingAmount;
  final double progressPercentage;
  final String status;
  final List<TransactionEntity> transactions;

  const DebtEntity({
    required this.id,
    required this.transactionType,
    required this.originalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.progressPercentage,
    required this.status,
    required this.transactions,
  });
}

// Data Model
class DebtModel extends DebtEntity {
  const DebtModel({
    required super.id,
    required super.transactionType,
    required super.originalAmount,
    required super.paidAmount,
    required super.outstandingAmount,
    required super.progressPercentage,
    required super.status,
    required super.transactions,
  });

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      originalAmount: double.tryParse(json['original_amount']?.toString() ?? '0') ?? 0.0,
      paidAmount: double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0.0,
      outstandingAmount: double.tryParse(json['outstanding_amount']?.toString() ?? '0') ?? 0.0,
      progressPercentage: double.tryParse(json['progress_percentage']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? '',
      transactions: (json['transactions'] as List?)
              ?.map((t) => TransactionModel.fromJson(t))
              .toList() ??
          [],
    );
  }
}
