import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    super.phoneNumber,
    super.email,
    super.avatarUrl,
    super.defaultCurrency,
    required super.hasPin,
    super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      defaultCurrency: json['default_currency'] as String?,
      hasPin: json['has_pin'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      phoneNumber: user.phoneNumber,
      email: user.email,
      avatarUrl: user.avatarUrl,
      defaultCurrency: user.defaultCurrency,
      hasPin: user.hasPin,
      createdAt: user.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'email': email,
      'avatar_url': avatarUrl,
      'default_currency': defaultCurrency,
      'has_pin': hasPin,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
