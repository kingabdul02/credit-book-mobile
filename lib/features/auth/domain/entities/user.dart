class User {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? defaultCurrency;
  final bool hasPin;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.defaultCurrency,
    required this.hasPin,
    this.createdAt,
  });
}
