import '../../domain/entities/debt_with_contact_entity.dart';
import '../../domain/entities/contact_entity.dart';

class DebtWithContactModel extends DebtWithContactEntity {
  const DebtWithContactModel({
    required super.id,
    required super.transactionType,
    required super.originalAmount,
    required super.paidAmount,
    required super.outstandingAmount,
    required super.progressPercentage,
    required super.status,
    required super.statusLabel,
    required super.statusColor,
    super.note,
    super.category,
    super.dueDate,
    required super.isOverdue,
    required super.createdAt,
    required super.updatedAt,
    super.contact,
  });

  factory DebtWithContactModel.fromJson(Map<String, dynamic> json) {
    return DebtWithContactModel(
      id: json['id'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      originalAmount: double.tryParse(json['original_amount']?.toString() ?? '0') ?? 0.0,
      paidAmount: double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0.0,
      outstandingAmount: double.tryParse(json['outstanding_amount']?.toString() ?? '0') ?? 0.0,
      progressPercentage: double.tryParse(json['progress_percentage']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? '',
      statusLabel: json['status_label'] ?? '',
      statusColor: json['status_color'] ?? '#000000',
      note: json['note'],
      category: json['category'],
      dueDate: json['due_date'],
      isOverdue: json['is_overdue'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      contact: json['contact'] != null
          ? _ContactEntityFromJson(json['contact'])
          : null,
    );
  }

  static ContactEntity _ContactEntityFromJson(Map<String, dynamic> json) {
    return ContactEntity(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? 'Unknown',
      nickname: json['nickname'],
      profilePicture: json['profile_picture'],
      isFavorite: json['is_favorite'] ?? false,
      totalOwedToUser: 0.0,
      totalUserOwes: 0.0,
      updatedAt: json['updated_at'] ?? '',
    );
  }
}
