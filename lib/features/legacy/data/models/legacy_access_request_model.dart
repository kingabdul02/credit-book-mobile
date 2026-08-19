import '../../domain/entities/legacy_access_request_entity.dart';
import '../../domain/entities/legacy_contact_entity.dart';
import 'legacy_contact_model.dart';

class LegacyAccessRequestModel extends LegacyAccessRequestEntity {
  const LegacyAccessRequestModel({
    required super.id,
    super.legacyContact,
    required super.reason,
    required super.recoveryCodeProvided,
    required super.status,
    super.statusLabel,
    required super.grantsAccess,
    required super.waitingPeriodDays,
    super.requestedAt,
    super.expiresAt,
    super.approvedAt,
    super.deniedAt,
    super.createdAt,
  });

  factory LegacyAccessRequestModel.fromJson(Map<String, dynamic> json) {
    LegacyContactEntity? contact;
    if (json['legacy_contact'] != null && json['legacy_contact'] is Map<String, dynamic>) {
      contact = LegacyContactModel.fromJson(json['legacy_contact'] as Map<String, dynamic>);
    }

    return LegacyAccessRequestModel(
      id: json['id']?.toString() ?? '',
      legacyContact: contact,
      reason: json['reason']?.toString() ?? '',
      recoveryCodeProvided: json['recovery_code_provided'] == true,
      status: json['status']?.toString() ?? 'PENDING',
      statusLabel: json['status_label']?.toString(),
      grantsAccess: json['grants_access'] == true,
      waitingPeriodDays: (json['waiting_period_days'] as num?)?.toInt() ?? 30,
      requestedAt: json['requested_at']?.toString(),
      expiresAt: json['expires_at']?.toString(),
      approvedAt: json['approved_at']?.toString(),
      deniedAt: json['denied_at']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}
