import 'dart:convert';
import 'dart:io';
import '../../../../core/services/connectivity_manager.dart';
import '../../../../core/services/app_cache_manager.dart';
import '../../domain/entities/dashboard_entities.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';
import '../datasources/home_local_data_source.dart';
import '../models/dashboard_models.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;
  final HomeLocalDataSource localDataSource;
  final AppCacheManager? cacheManager;

  static const String cacheKey = 'dashboard_data';

  HomeRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    this.cacheManager,
  });

  @override
  DashboardData? getCachedDashboardData() {
    final memory = cacheManager?.get<DashboardData>(cacheKey);
    if (memory != null) return memory;
    try {
      if (localDataSource is HomeLocalDataSourceImpl) {
        final jsonString = (localDataSource as HomeLocalDataSourceImpl)
            .sharedPreferences
            .getString('cached_dashboard');
        if (jsonString != null && jsonString.isNotEmpty) {
          final local = DashboardDataModel.fromJson(jsonDecode(jsonString));
          cacheManager?.put<DashboardData>(cacheKey, local, ttl: const Duration(minutes: 3));
          return local;
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<DashboardData> getDashboardData({bool forceRefresh = false}) async {
    // 1. If not forcing refresh and memory cache is fresh, return immediately
    if (!forceRefresh && cacheManager != null && cacheManager!.isFresh(cacheKey)) {
      final cached = cacheManager!.get<DashboardData>(cacheKey);
      if (cached != null) return cached;
    }

    // Fast path: if offline, return local data immediately
    if (!ConnectivityManager.instance.isOnline) {
      return await _fetchLocalData();
    }

    // 2. Fetch fresh from remote
    try {
      final data = await remoteDataSource.getDashboard();
      cacheManager?.put<DashboardData>(
        cacheKey,
        data,
        ttl: const Duration(minutes: 3),
      );
      await localDataSource.cacheDashboard(data);
      return data;
    } on SocketException {
      return await _fetchLocalData();
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('ClientException')) {
        return await _fetchLocalData();
      }
      // Return stale cache if available when remote fails
      final stale = cacheManager?.get<DashboardData>(cacheKey);
      if (stale != null) return stale;
      rethrow;
    }
  }
  
  Future<DashboardData> _fetchLocalData() async {
    final memoryCached = cacheManager?.get<DashboardData>(cacheKey);
    if (memoryCached != null) return memoryCached;

    try {
      final local = await localDataSource.getLastDashboard();
      cacheManager?.put<DashboardData>(cacheKey, local, ttl: const Duration(minutes: 3));
      return local;
    } catch (e) {
      throw Exception('No internet connection and no cached data available.');
    }
  }
}
