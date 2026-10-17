import '../../domain/entities/insights_entity.dart';
import '../../domain/repositories/insights_repository.dart';
import '../datasources/insights_remote_data_source.dart';
import '../../../../core/services/app_cache_manager.dart';

class InsightsRepositoryImpl implements InsightsRepository {
  final InsightsRemoteDataSource remoteDataSource;
  final AppCacheManager? cacheManager;

  InsightsRepositoryImpl({
    required this.remoteDataSource,
    this.cacheManager,
  });

  @override
  InsightsDataEntity? getCachedInsightsData(String timeframe) {
    return cacheManager?.get<InsightsDataEntity>('insights_$timeframe');
  }

  @override
  Future<InsightsDataEntity> getInsightsData(
    String timeframe, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'insights_$timeframe';
    if (!forceRefresh && cacheManager != null && cacheManager!.isFresh(cacheKey)) {
      final cached = cacheManager!.get<InsightsDataEntity>(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final data = await remoteDataSource.getInsightsData(timeframe);
      cacheManager?.put<InsightsDataEntity>(
        cacheKey,
        data,
        ttl: const Duration(minutes: 5),
      );
      return data;
    } catch (e) {
      final stale = cacheManager?.get<InsightsDataEntity>(cacheKey);
      if (stale != null) return stale;
      rethrow;
    }
  }
}
