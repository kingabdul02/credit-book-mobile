class LegacyContactEntity {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String relationship;
  final bool isPrimary;
  final String verificationStatus; // PENDING | VERIFIED | REVOKED
  final String? verifiedAt;
  final int accessRequestsCount;
  final String? createdAt;

  const LegacyContactEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.relationship,
    required this.isPrimary,
    required this.verificationStatus,
    this.verifiedAt,
    this.accessRequestsCount = 0,
    this.createdAt,
  });

  bool get isVerified => verificationStatus == 'VERIFIED';
  bool get isPending => verificationStatus == 'PENDING';
  bool get isRevoked => verificationStatus == 'REVOKED';

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length > 1) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.substring(0, fullName.length >= 2 ? 2 : 1).toUpperCase();
  }
}

class LegacySettingsEntity {
  final bool legacyAccessEnabled;
  final int legacyWaitingPeriodDays;
  final bool hasRecoveryCode;
  final int contactsCount;
  final int verifiedContactsCount;

  const LegacySettingsEntity({
    required this.legacyAccessEnabled,
    required this.legacyWaitingPeriodDays,
    required this.hasRecoveryCode,
    required this.contactsCount,
    required this.verifiedContactsCount,
  });
}
