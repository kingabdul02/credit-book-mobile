import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    super.phoneNumber,
    super.defaultCurrency,
    required super.hasPin,
    super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String?,
      defaultCurrency: json['default_currency'] as String?,
      hasPin: json['has_pin'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'default_currency': defaultCurrency,
      'has_pin': hasPin,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
