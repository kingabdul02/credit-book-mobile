// Domain Entity
class TransactionEntity {
  final String id;
  final String type; // 'payment' or 'debt_issuance' (based on backend LedgerType)
  final double amount;
  final String? note;
  final String createdAt;

  const TransactionEntity({
    required this.id,
    required this.type,
    required this.amount,
    this.note,
    required this.createdAt,
  });
}

// Data Model
class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.type,
    required super.amount,
    super.note,
    required super.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      note: json['note'],
      createdAt: json['created_at'] ?? '',
    );
  }

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      type: entity.type,
      amount: entity.amount,
      note: entity.note,
      createdAt: entity.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'note': note,
      'created_at': createdAt,
    };
  }
}
