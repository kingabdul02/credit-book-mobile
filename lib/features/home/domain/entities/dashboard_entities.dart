class Contact {
  final String id;
  final String fullName;
  final String? nickname;

  const Contact({
    required this.id,
    required this.fullName,
    this.nickname,
  });
}

class Debt {
  final String id;
  final Contact? contact;
  final String transactionType; // e.g., 'they_owe_me', 'i_owe_them'
  final String statusLabel; // e.g., 'Unpaid', 'Received'
  final String? dueDate;

  const Debt({
    required this.id,
    this.contact,
    required this.transactionType,
    required this.statusLabel,
    this.dueDate,
  });
}

class Transaction {
  final String id;
  final Debt? debt;
  final String amount;
  final String type; // e.g., 'PAYMENT', 'ADDITIONAL'
  final String createdAt;

  const Transaction({
    required this.id,
    this.debt,
    required this.amount,
    required this.type,
    required this.createdAt,
  });
}

class Reminder {
  final String id;
  final Debt? debt;
  final String? remindAt;
  final String typeLabel;

  const Reminder({
    required this.id,
    this.debt,
    this.remindAt,
    required this.typeLabel,
  });
}

class DashboardMetrics {
  final String totalOwedToMe;
  final String totalIOwe;
  final String netBalance;
  final int activeDebtsCount;
  final int overdueCount;

  const DashboardMetrics({
    required this.totalOwedToMe,
    required this.totalIOwe,
    required this.netBalance,
    required this.activeDebtsCount,
    required this.overdueCount,
  });
}

class DashboardData {
  final DashboardMetrics metrics;
  final List<Reminder> upcomingReminders;
  final List<Transaction> recentTransactions;

  const DashboardData({
    required this.metrics,
    required this.upcomingReminders,
    required this.recentTransactions,
  });
}
