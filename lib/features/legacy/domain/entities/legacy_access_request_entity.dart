import 'legacy_contact_entity.dart';

class LegacyAccessRequestEntity {
  final String id;
  final LegacyContactEntity? legacyContact;
  final String reason;
  final bool recoveryCodeProvided;
  final String status; // PENDING | APPROVED | DENIED | AUTO_APPROVED
  final String? statusLabel;
  final bool grantsAccess;
  final int waitingPeriodDays;
  final String? requestedAt;
  final String? expiresAt;
  final String? approvedAt;
  final String? deniedAt;
  final String? createdAt;

  const LegacyAccessRequestEntity({
    required this.id,
    this.legacyContact,
    required this.reason,
    required this.recoveryCodeProvided,
    required this.status,
    this.statusLabel,
    required this.grantsAccess,
    required this.waitingPeriodDays,
    this.requestedAt,
    this.expiresAt,
    this.approvedAt,
    this.deniedAt,
    this.createdAt,
  });

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED' || status == 'AUTO_APPROVED';
  bool get isDenied => status == 'DENIED';
  bool get isAutoApproved => status == 'AUTO_APPROVED';

  /// Human-friendly reason label.
  String get reasonLabel {
    switch (reason.toLowerCase()) {
      case 'deceased':
        return 'Deceased';
      case 'permanent_incapacity':
        return 'Permanent Incapacity';
      case 'medical_emergency':
        return 'Medical Emergency';
      default:
        return reason;
    }
  }
}

// ─── Estate Report Entities ──────────────────────────────────────────────────

class EstateDebtItemEntity {
  final String contactName;
  final double amount;
  final String currency;
  final String? note;

  const EstateDebtItemEntity({
    required this.contactName,
    required this.amount,
    required this.currency,
    this.note,
  });
}

class EstateAccountOwnerEntity {
  final String name;
  final String email;

  const EstateAccountOwnerEntity({
    required this.name,
    required this.email,
  });
}

class EstateReportEntity {
  final EstateAccountOwnerEntity accountOwner;
  final List<EstateDebtItemEntity> receivableItems;
  final double totalReceivables;
  final List<EstateDebtItemEntity> payableItems;
  final double totalPayables;
  final double netPosition;
  final String currency;
  final String generatedAt;

  const EstateReportEntity({
    required this.accountOwner,
    required this.receivableItems,
    required this.totalReceivables,
    required this.payableItems,
    required this.totalPayables,
    required this.netPosition,
    required this.currency,
    required this.generatedAt,
  });
}
