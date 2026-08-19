import 'contact_entity.dart';

class DebtStatistics {
  final int totalDebts;
  final int pendingCount;
  final int settledCount;
  final double totalPending;
  final double totalSettled;
  final double iOwePending;
  final double theyOweMePending;
  final double iOweSettled;
  final double theyOweMeSettled;

  const DebtStatistics({
    required this.totalDebts,
    required this.pendingCount,
    required this.settledCount,
    required this.totalPending,
    required this.totalSettled,
    required this.iOwePending,
    required this.theyOweMePending,
    required this.iOweSettled,
    required this.theyOweMeSettled,
  });
}

class DebtWithContactEntity {
  final String id;
  final String transactionType;
  final double originalAmount;
  final double paidAmount;
  final double outstandingAmount;
  final double progressPercentage;
  final String status;
  final String statusLabel;
  final String statusColor;
  final String? note;
  final String? category;
  final String? dueDate;
  final bool isOverdue;
  final String createdAt;
  final String updatedAt;
  final ContactEntity? contact;

  const DebtWithContactEntity({
    required this.id,
    required this.transactionType,
    required this.originalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.progressPercentage,
    required this.status,
    required this.statusLabel,
    required this.statusColor,
    this.note,
    this.category,
    this.dueDate,
    required this.isOverdue,
    required this.createdAt,
    required this.updatedAt,
    this.contact,
  });

  bool get isPending => status == 'UNPAID' || status == 'PARTIALLY_PAID';
  bool get isSettled => status == 'PAID';
  bool get isIOweThem => transactionType.toUpperCase() == 'I_OWE_THEM';
  bool get isTheyOweMe => transactionType.toUpperCase() == 'THEY_OWE_ME';
}
