import '../../domain/entities/legacy_contact_entity.dart';
import '../../domain/entities/legacy_access_request_entity.dart';
import '../../domain/repositories/legacy_repository.dart';
import '../datasources/legacy_remote_data_source.dart';
import '../../../../core/services/app_cache_manager.dart';

class LegacyRepositoryImpl implements LegacyRepository {
  final LegacyRemoteDataSource remoteDataSource;
  final AppCacheManager? cacheManager;

  static const String settingsCacheKey = 'legacy_settings';
  static const String contactsCacheKey = 'legacy_contacts';
  static const String accessRequestsCacheKey = 'legacy_access_requests';

  LegacyRepositoryImpl({
    required this.remoteDataSource,
    this.cacheManager,
  });

  @override
  LegacySettingsEntity? getCachedSettings() {
    return cacheManager?.get<LegacySettingsEntity>(settingsCacheKey);
  }

  @override
  List<LegacyContactEntity>? getCachedLegacyContacts() {
    return cacheManager?.get<List<LegacyContactEntity>>(contactsCacheKey);
  }

  @override
  List<LegacyAccessRequestEntity>? getCachedAccessRequests() {
    return cacheManager?.get<List<LegacyAccessRequestEntity>>(accessRequestsCacheKey);
  }

  @override
  Future<LegacySettingsEntity> getSettings({bool forceRefresh = false}) async {
    if (!forceRefresh && cacheManager != null && cacheManager!.isFresh(settingsCacheKey)) {
      final cached = cacheManager!.get<LegacySettingsEntity>(settingsCacheKey);
      if (cached != null) return cached;
    }

    try {
      final settings = await remoteDataSource.getSettings();
      cacheManager?.put<LegacySettingsEntity>(
        settingsCacheKey,
        settings,
        ttl: const Duration(minutes: 5),
      );
      return settings;
    } catch (e) {
      final stale = cacheManager?.get<LegacySettingsEntity>(settingsCacheKey);
      if (stale != null) return stale;
      rethrow;
    }
  }

  @override
  Future<String?> enableLegacyAccess() async {
    final code = await remoteDataSource.enableLegacyAccess();
    _invalidateLegacyCaches();
    return code;
  }

  @override
  Future<void> disableLegacyAccess() async {
    await remoteDataSource.disableLegacyAccess();
    _invalidateLegacyCaches();
  }

  @override
  Future<List<LegacyContactEntity>> getLegacyContacts({bool forceRefresh = false}) async {
    if (!forceRefresh && cacheManager != null && cacheManager!.isFresh(contactsCacheKey)) {
      final cached = cacheManager!.get<List<LegacyContactEntity>>(contactsCacheKey);
      if (cached != null) return cached;
    }

    try {
      final contacts = await remoteDataSource.getLegacyContacts();
      cacheManager?.put<List<LegacyContactEntity>>(
        contactsCacheKey,
        contacts,
        ttl: const Duration(minutes: 5),
      );
      return contacts;
    } catch (e) {
      final stale = cacheManager?.get<List<LegacyContactEntity>>(contactsCacheKey);
      if (stale != null) return stale;
      rethrow;
    }
  }

  @override
  Future<LegacyContactEntity> createLegacyContact(Map<String, dynamic> data) async {
    final contact = await remoteDataSource.createLegacyContact(data);
    _invalidateLegacyCaches();
    return contact;
  }

  @override
  Future<LegacyContactEntity> updateLegacyContact(String id, Map<String, dynamic> data) async {
    final contact = await remoteDataSource.updateLegacyContact(id, data);
    _invalidateLegacyCaches();
    return contact;
  }

  @override
  Future<void> deleteLegacyContact(String id) async {
    await remoteDataSource.deleteLegacyContact(id);
    _invalidateLegacyCaches();
  }

  @override
  Future<void> resendVerification(String id) => remoteDataSource.resendVerification(id);

  @override
  Future<void> revokeLegacyContact(String id) async {
    await remoteDataSource.revokeLegacyContact(id);
    _invalidateLegacyCaches();
  }

  // ── Access Requests ────────────────────────────────────────
  @override
  Future<LegacyAccessRequestEntity> submitAccessRequest(Map<String, dynamic> data) async {
    final req = await remoteDataSource.submitAccessRequest(data);
    cacheManager?.invalidate(accessRequestsCacheKey);
    return req;
  }

  @override
  Future<List<LegacyAccessRequestEntity>> getAccessRequests({bool forceRefresh = false}) async {
    if (!forceRefresh && cacheManager != null && cacheManager!.isFresh(accessRequestsCacheKey)) {
      final cached = cacheManager!.get<List<LegacyAccessRequestEntity>>(accessRequestsCacheKey);
      if (cached != null) return cached;
    }

    try {
      final list = await remoteDataSource.getAccessRequests();
      cacheManager?.put<List<LegacyAccessRequestEntity>>(
        accessRequestsCacheKey,
        list,
        ttl: const Duration(minutes: 3),
      );
      return list;
    } catch (e) {
      final stale = cacheManager?.get<List<LegacyAccessRequestEntity>>(accessRequestsCacheKey);
      if (stale != null) return stale;
      rethrow;
    }
  }

  @override
  Future<LegacyAccessRequestEntity> approveAccessRequest(String id) async {
    final res = await remoteDataSource.approveAccessRequest(id);
    _invalidateLegacyCaches();
    return res;
  }

  @override
  Future<LegacyAccessRequestEntity> denyAccessRequest(String id) async {
    final res = await remoteDataSource.denyAccessRequest(id);
    _invalidateLegacyCaches();
    return res;
  }

  @override
  Future<EstateReportEntity> getEstateReport(String requestId) =>
      remoteDataSource.getEstateReport(requestId);

  void _invalidateLegacyCaches() {
    cacheManager?.invalidate(settingsCacheKey);
    cacheManager?.invalidate(contactsCacheKey);
    cacheManager?.invalidate(accessRequestsCacheKey);
  }
}
