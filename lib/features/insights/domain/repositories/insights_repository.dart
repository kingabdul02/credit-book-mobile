import '../entities/insights_entity.dart';

abstract class InsightsRepository {
  /// Fetches the insights data based on a time filter (e.g., 'weekly', 'monthly', 'yearly')
  Future<InsightsDataEntity> getInsightsData(String timeframe, {bool forceRefresh = false});
  InsightsDataEntity? getCachedInsightsData(String timeframe);
}
