import '../entities/dashboard_entities.dart';

abstract class HomeRepository {
  Future<DashboardData> getDashboardData();
}
