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
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] ?? 'Unknown',
      nickname: json['nickname'],
      profilePicture: json['profile_picture'],
      isFavorite: json['is_favorite'] == true,
      totalOwedToUser: double.tryParse(json['total_owed_to_user']?.toString() ?? '0') ?? 0.0,
      totalUserOwes: double.tryParse(json['total_user_owes']?.toString() ?? '0') ?? 0.0,
      updatedAt: json['updated_at']?.toString() ?? '',
      debts: (json['debts'] as List?)?.map((d) => DebtModel.fromJson(d)).toList(),
    );
  }

  factory ContactModel.fromEntity(ContactEntity entity) {
    return ContactModel(
      id: entity.id,
      fullName: entity.fullName,
      nickname: entity.nickname,
      profilePicture: entity.profilePicture,
      isFavorite: entity.isFavorite,
      totalOwedToUser: entity.totalOwedToUser,
      totalUserOwes: entity.totalUserOwes,
      updatedAt: entity.updatedAt,
      debts: entity.debts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'nickname': nickname,
      'profile_picture': profilePicture,
      'is_favorite': isFavorite,
      'total_owed_to_user': totalOwedToUser,
      'total_user_owes': totalUserOwes,
      'updated_at': updatedAt,
    };
  }
}
