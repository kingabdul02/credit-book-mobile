import '../../domain/entities/legacy_contact_entity.dart';

class LegacyContactModel extends LegacyContactEntity {
  const LegacyContactModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.phone,
    required super.relationship,
    required super.isPrimary,
    required super.verificationStatus,
    super.verifiedAt,
    super.accessCode,
    super.accessRequestsCount,
    super.createdAt,
  });

  factory LegacyContactModel.fromJson(Map<String, dynamic> json) {
    return LegacyContactModel(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? '',
      isPrimary: json['is_primary'] == true || json['is_primary'] == 1,
      verificationStatus: json['verification_status']?.toString() ?? 'PENDING',
      verifiedAt: json['verified_at']?.toString(),
      accessCode: json['access_code']?.toString(),
      accessRequestsCount: (json['access_requests_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'relationship': relationship,
        'is_primary': isPrimary,
      };
}

class LegacySettingsModel extends LegacySettingsEntity {
  const LegacySettingsModel({
    required super.legacyAccessEnabled,
    required super.legacyWaitingPeriodDays,
    required super.hasRecoveryCode,
    required super.contactsCount,
    required super.verifiedContactsCount,
  });

  factory LegacySettingsModel.fromJson(Map<String, dynamic> json) {
    return LegacySettingsModel(
      legacyAccessEnabled: json['legacy_access_enabled'] == true,
      legacyWaitingPeriodDays: (json['legacy_waiting_period_days'] as num?)?.toInt() ?? 30,
      hasRecoveryCode: json['has_recovery_code'] == true,
      contactsCount: (json['contacts_count'] as num?)?.toInt() ?? 0,
      verifiedContactsCount: (json['verified_contacts_count'] as num?)?.toInt() ?? 0,
    );
  }
}
