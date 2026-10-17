class TwoFactorRequiredException implements Exception {
  final String twoFactorToken;
  final String phoneNumber;
  final String? email;
  final String? debugCode;
  final String method;
  final String defaultMethod;
  final List<String> availableMethods;
  final String? maskedPhone;

  const TwoFactorRequiredException({
    required this.twoFactorToken,
    required this.phoneNumber,
    this.email,
    this.debugCode,
    this.method = 'authenticator',
    this.defaultMethod = 'authenticator',
    this.availableMethods = const ['authenticator', 'email', 'phone'],
    this.maskedPhone,
  });

  @override
  String toString() => 'TwoFactorRequiredException: 2FA challenge ($method) required for $phoneNumber';
}
