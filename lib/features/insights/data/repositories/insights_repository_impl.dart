import '../../domain/entities/insights_entity.dart';
import '../../domain/repositories/insights_repository.dart';
import '../datasources/insights_remote_data_source.dart';

class InsightsRepositoryImpl implements InsightsRepository {
  final InsightsRemoteDataSource remoteDataSource;

  InsightsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<InsightsDataEntity> getInsightsData(String timeframe) async {
    return remoteDataSource.getInsightsData(timeframe);
  }
}
