import '../../domain/entities/legacy_contact_entity.dart';
import '../../domain/entities/legacy_access_request_entity.dart';
import '../../domain/repositories/legacy_repository.dart';
import '../datasources/legacy_remote_data_source.dart';

class LegacyRepositoryImpl implements LegacyRepository {
  final LegacyRemoteDataSource remoteDataSource;

  LegacyRepositoryImpl({required this.remoteDataSource});

  @override
  Future<LegacySettingsEntity> getSettings() => remoteDataSource.getSettings();

  @override
  Future<String?> enableLegacyAccess() => remoteDataSource.enableLegacyAccess();

  @override
  Future<void> disableLegacyAccess() => remoteDataSource.disableLegacyAccess();

  @override
  Future<List<LegacyContactEntity>> getLegacyContacts() => remoteDataSource.getLegacyContacts();

  @override
  Future<LegacyContactEntity> createLegacyContact(Map<String, dynamic> data) =>
      remoteDataSource.createLegacyContact(data);

  @override
  Future<LegacyContactEntity> updateLegacyContact(String id, Map<String, dynamic> data) =>
      remoteDataSource.updateLegacyContact(id, data);

  @override
  Future<void> deleteLegacyContact(String id) => remoteDataSource.deleteLegacyContact(id);

  @override
  Future<void> resendVerification(String id) => remoteDataSource.resendVerification(id);

  @override
  Future<void> revokeLegacyContact(String id) => remoteDataSource.revokeLegacyContact(id);

  // ── Access Requests ────────────────────────────────────────
  @override
  Future<LegacyAccessRequestEntity> submitAccessRequest(Map<String, dynamic> data) =>
      remoteDataSource.submitAccessRequest(data);

  @override
  Future<List<LegacyAccessRequestEntity>> getAccessRequests() =>
      remoteDataSource.getAccessRequests();

  @override
  Future<LegacyAccessRequestEntity> approveAccessRequest(String id) =>
      remoteDataSource.approveAccessRequest(id);

  @override
  Future<LegacyAccessRequestEntity> denyAccessRequest(String id) =>
      remoteDataSource.denyAccessRequest(id);

  @override
  Future<EstateReportEntity> getEstateReport(String requestId) =>
      remoteDataSource.getEstateReport(requestId);
}
