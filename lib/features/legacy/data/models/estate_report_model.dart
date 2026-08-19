import '../../domain/entities/legacy_access_request_entity.dart';

class EstateReportModel extends EstateReportEntity {
  const EstateReportModel({
    required super.accountOwner,
    required super.receivableItems,
    required super.totalReceivables,
    required super.payableItems,
    required super.totalPayables,
    required super.netPosition,
    required super.currency,
    required super.generatedAt,
  });

  factory EstateReportModel.fromJson(Map<String, dynamic> json) {
    final owner = json['account_owner'] as Map<String, dynamic>? ?? {};
    final receivables = json['receivables'] as Map<String, dynamic>? ?? {};
    final payables = json['payables'] as Map<String, dynamic>? ?? {};

    final receivableItems = (receivables['items'] as List? ?? [])
        .map((e) => EstateDebtItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final payableItems = (payables['items'] as List? ?? [])
        .map((e) => EstateDebtItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return EstateReportModel(
      accountOwner: EstateAccountOwnerModel.fromJson(owner),
      receivableItems: receivableItems,
      totalReceivables: (receivables['total'] as num?)?.toDouble() ?? 0.0,
      payableItems: payableItems,
      totalPayables: (payables['total'] as num?)?.toDouble() ?? 0.0,
      netPosition: (json['net_position'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'NGN',
      generatedAt: json['generated_at']?.toString() ?? '',
    );
  }
}

class EstateDebtItemModel extends EstateDebtItemEntity {
  const EstateDebtItemModel({
    required super.contactName,
    required super.amount,
    required super.currency,
    super.note,
  });

  factory EstateDebtItemModel.fromJson(Map<String, dynamic> json) {
    return EstateDebtItemModel(
      contactName: json['contact_name']?.toString() ?? 'Unknown',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'NGN',
      note: json['note']?.toString(),
    );
  }
}

class EstateAccountOwnerModel extends EstateAccountOwnerEntity {
  const EstateAccountOwnerModel({
    required super.name,
    required super.email,
  });

  factory EstateAccountOwnerModel.fromJson(Map<String, dynamic> json) {
    return EstateAccountOwnerModel(
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}
