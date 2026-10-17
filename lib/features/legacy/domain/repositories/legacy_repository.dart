import '../entities/legacy_contact_entity.dart';
import '../entities/legacy_access_request_entity.dart';

abstract class LegacyRepository {
  Future<LegacySettingsEntity> getSettings({bool forceRefresh = false});
  LegacySettingsEntity? getCachedSettings();

  Future<String?> enableLegacyAccess(); // returns recovery code
  Future<void> disableLegacyAccess();

  Future<List<LegacyContactEntity>> getLegacyContacts({bool forceRefresh = false});
  List<LegacyContactEntity>? getCachedLegacyContacts();

  Future<LegacyContactEntity> createLegacyContact(Map<String, dynamic> data);
  Future<LegacyContactEntity> updateLegacyContact(String id, Map<String, dynamic> data);
  Future<void> deleteLegacyContact(String id);
  Future<void> resendVerification(String id);
  Future<void> revokeLegacyContact(String id);

  // ── Access Requests ────────────────────────────────────────
  Future<LegacyAccessRequestEntity> submitAccessRequest(Map<String, dynamic> data);
  Future<List<LegacyAccessRequestEntity>> getAccessRequests({bool forceRefresh = false});
  List<LegacyAccessRequestEntity>? getCachedAccessRequests();

  Future<LegacyAccessRequestEntity> approveAccessRequest(String id);
  Future<LegacyAccessRequestEntity> denyAccessRequest(String id);
  Future<EstateReportEntity> getEstateReport(String requestId);
}
