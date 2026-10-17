import '../entities/dashboard_entities.dart';

abstract class HomeRepository {
  Future<DashboardData> getDashboardData({bool forceRefresh = false});
  DashboardData? getCachedDashboardData();
}
