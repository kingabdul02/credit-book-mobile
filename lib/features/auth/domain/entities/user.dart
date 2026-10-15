class User {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? email;
  final String? avatarUrl;
  final String? defaultCurrency;
  final bool hasPin;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.email,
    this.avatarUrl,
    this.defaultCurrency,
    required this.hasPin,
    this.createdAt,
  });

  User copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    String? avatarUrl,
    bool clearAvatarUrl = false,
    String? defaultCurrency,
    bool? hasPin,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      hasPin: hasPin ?? this.hasPin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
