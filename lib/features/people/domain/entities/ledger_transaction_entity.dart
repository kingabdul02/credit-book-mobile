class LedgerTransactionEntity {
  final String title;
  final String subtitle;
  final double amount;
  final bool isPositive; 
  final String date; 
  final String time; 
  final String type; 
  final String transactionType;

  const LedgerTransactionEntity({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isPositive,
    required this.date,
    required this.time,
    required this.type,
    required this.transactionType,
  });
}
