import '../../domain/entities/dashboard_entities.dart';

class ContactModel extends Contact {
  const ContactModel({
    required super.id,
    required super.fullName,
    super.nickname,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      nickname: json['nickname'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'nickname': nickname,
    };
  }
}

class DebtModel extends Debt {
  const DebtModel({
    required super.id,
    super.contact,
    required super.transactionType,
    required super.statusLabel,
    super.dueDate,
  });

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id'] ?? '',
      contact: json['contact'] != null ? ContactModel.fromJson(json['contact']) : null,
      transactionType: json['transaction_type'] ?? '',
      statusLabel: json['status_label'] ?? '',
      dueDate: json['due_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contact': (contact as ContactModel?)?.toJson(),
      'transaction_type': transactionType,
      'status_label': statusLabel,
      'due_date': dueDate,
    };
  }
}

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    super.debt,
    required super.amount,
    required super.type,
    required super.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      debt: json['debt'] != null ? DebtModel.fromJson(json['debt']) : null,
      amount: json['amount']?.toString() ?? '0',
      type: json['type'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'debt': (debt as DebtModel?)?.toJson(),
      'amount': amount,
      'type': type,
      'created_at': createdAt,
    };
  }
}

class ReminderModel extends Reminder {
  const ReminderModel({
    required super.id,
    super.debt,
    super.remindAt,
    required super.typeLabel,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] ?? '',
      debt: json['debt'] != null ? DebtModel.fromJson(json['debt']) : null,
      remindAt: json['remind_at'],
      typeLabel: json['type_label'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'debt': (debt as DebtModel?)?.toJson(),
      'remind_at': remindAt,
      'type_label': typeLabel,
    };
  }
}

class DashboardMetricsModel extends DashboardMetrics {
  const DashboardMetricsModel({
    required super.totalOwedToMe,
    required super.totalIOwe,
    required super.netBalance,
    required super.activeDebtsCount,
    required super.overdueCount,
  });

  factory DashboardMetricsModel.fromJson(Map<String, dynamic> json) {
    return DashboardMetricsModel(
      totalOwedToMe: json['total_owed_to_me']?.toString() ?? '0',
      totalIOwe: json['total_i_owe']?.toString() ?? '0',
      netBalance: json['net_balance']?.toString() ?? '0',
      activeDebtsCount: json['active_debts_count'] ?? 0,
      overdueCount: json['overdue_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_owed_to_me': totalOwedToMe,
      'total_i_owe': totalIOwe,
      'net_balance': netBalance,
      'active_debts_count': activeDebtsCount,
      'overdue_count': overdueCount,
    };
  }
}

class DashboardDataModel extends DashboardData {
  const DashboardDataModel({
    required super.metrics,
    required super.upcomingReminders,
    required super.recentTransactions,
  });

  factory DashboardDataModel.fromJson(Map<String, dynamic> json) {
    return DashboardDataModel(
      metrics: DashboardMetricsModel.fromJson(json['dashboard'] ?? {}),
      upcomingReminders: (json['upcoming_reminders'] as List?)
              ?.map((e) => ReminderModel.fromJson(e))
              .toList() ??
          [],
      recentTransactions: (json['recent_transactions'] as List?)
              ?.map((e) => TransactionModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dashboard': (metrics as DashboardMetricsModel).toJson(),
      'upcoming_reminders': upcomingReminders.map((e) => (e as ReminderModel).toJson()).toList(),
      'recent_transactions': recentTransactions.map((e) => (e as TransactionModel).toJson()).toList(),
    };
  }
}
