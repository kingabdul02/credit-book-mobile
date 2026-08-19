import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_models.dart';

abstract class HomeLocalDataSource {
  Future<DashboardDataModel> getLastDashboard();
  Future<void> cacheDashboard(DashboardDataModel dashboardData);
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const _cachedDashboardKey = 'cached_dashboard';

  HomeLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<DashboardDataModel> getLastDashboard() {
    final jsonString = sharedPreferences.getString(_cachedDashboardKey);
    if (jsonString != null) {
      return Future.value(DashboardDataModel.fromJson(jsonDecode(jsonString)));
    } else {
      throw Exception('No cached data');
    }
  }

  @override
  Future<void> cacheDashboard(DashboardDataModel dashboardData) {
    final jsonString = jsonEncode(dashboardData.toJson());
    return sharedPreferences.setString(_cachedDashboardKey, jsonString);
  }
}
