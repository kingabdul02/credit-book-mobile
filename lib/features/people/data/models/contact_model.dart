import '../../domain/entities/contact_entity.dart';
import 'debt_model.dart';

class ContactModel extends ContactEntity {
  const ContactModel({
    required super.id,
    required super.fullName,
    super.nickname,
    super.profilePicture,
    required super.isFavorite,
    required super.totalOwedToUser,
    required super.totalUserOwes,
    required super.updatedAt,
    super.debts,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? 'Unknown',
      nickname: json['nickname'],
      profilePicture: json['profile_picture'],
      isFavorite: json['is_favorite'] == true,
      totalOwedToUser: double.tryParse(json['total_owed_to_user']?.toString() ?? '0') ?? 0.0,
      totalUserOwes: double.tryParse(json['total_user_owes']?.toString() ?? '0') ?? 0.0,
      updatedAt: json['updated_at'] ?? '',
      debts: (json['debts'] as List?)?.map((d) => DebtModel.fromJson(d)).toList(),
    );
  }
}
