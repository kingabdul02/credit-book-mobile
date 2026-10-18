import '../../data/models/debt_model.dart';

class ContactEntity {
  final String id;
  final String fullName;
  final String? nickname;
  final String? profilePicture;
  final bool isFavorite;
  final double totalOwedToUser;
  final double totalUserOwes;
  final String updatedAt;
  final List<dynamic>? debts;

  const ContactEntity({
    required this.id,
    required this.fullName,
    this.nickname,
    this.profilePicture,
    required this.isFavorite,
    required this.totalOwedToUser,
    required this.totalUserOwes,
    required this.updatedAt,
    this.debts,
  });

  String get initials {
    if (fullName.isEmpty) return '?';
    final parts = fullName.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.substring(0, fullName.length >= 2 ? 2 : 1).toUpperCase();
  }

  ContactEntity copyWith({
    String? id,
    String? fullName,
    String? nickname,
    String? profilePicture,
    bool? isFavorite,
    double? totalOwedToUser,
    double? totalUserOwes,
    String? updatedAt,
    List<dynamic>? debts,
  }) {
    return ContactEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      nickname: nickname ?? this.nickname,
      profilePicture: profilePicture ?? this.profilePicture,
      isFavorite: isFavorite ?? this.isFavorite,
      totalOwedToUser: totalOwedToUser ?? this.totalOwedToUser,
      totalUserOwes: totalUserOwes ?? this.totalUserOwes,
      updatedAt: updatedAt ?? this.updatedAt,
      debts: debts ?? this.debts,
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
      if (debts != null)
        'debts': debts!.map((d) {
          if (d is DebtModel) return d.toJson();
          if (d is DebtEntity) return DebtModel.fromEntity(d).toJson();
          if (d is Map<String, dynamic>) return d;
          return null;
        }).where((d) => d != null).toList(),
    };
  }

  factory ContactEntity.fromJson(Map<String, dynamic> json) {
    return ContactEntity(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] ?? 'Unknown',
      nickname: json['nickname'],
      profilePicture: json['profile_picture'],
      isFavorite: json['is_favorite'] == true,
      totalOwedToUser: double.tryParse(json['total_owed_to_user']?.toString() ?? '0') ?? 0.0,
      totalUserOwes: double.tryParse(json['total_user_owes']?.toString() ?? '0') ?? 0.0,
      updatedAt: json['updated_at']?.toString() ?? '',
      debts: (json['debts'] as List?)
          ?.map((d) => d is Map<String, dynamic> ? DebtModel.fromJson(d) : d)
          .toList(),
    );
  }
}

class PeopleDataEntity {
  final List<ContactEntity> favorites;
  final List<ContactEntity> frequentlyContacted;
  final List<ContactEntity> allContacts;

  const PeopleDataEntity({
    required this.favorites,
    required this.frequentlyContacted,
    required this.allContacts,
  });

  Map<String, dynamic> toJson() {
    return {
      'favorites': favorites.map((c) => c.toJson()).toList(),
      'frequently_contacted': frequentlyContacted.map((c) => c.toJson()).toList(),
      'all_contacts': allContacts.map((c) => c.toJson()).toList(),
    };
  }

  factory PeopleDataEntity.fromJson(Map<String, dynamic> json) {
    return PeopleDataEntity(
      favorites: (json['favorites'] as List? ?? [])
          .map((item) => ContactEntity.fromJson(item as Map<String, dynamic>))
          .toList(),
      frequentlyContacted: (json['frequently_contacted'] as List? ?? [])
          .map((item) => ContactEntity.fromJson(item as Map<String, dynamic>))
          .toList(),
      allContacts: (json['all_contacts'] as List? ?? [])
          .map((item) => ContactEntity.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  PeopleDataEntity copyWith({
    List<ContactEntity>? favorites,
    List<ContactEntity>? frequentlyContacted,
    List<ContactEntity>? allContacts,
  }) {
    return PeopleDataEntity(
      favorites: favorites ?? this.favorites,
      frequentlyContacted: frequentlyContacted ?? this.frequentlyContacted,
      allContacts: allContacts ?? this.allContacts,
    );
  }
}
