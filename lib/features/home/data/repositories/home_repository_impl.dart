import '../../domain/entities/dashboard_entities.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';
import '../datasources/home_local_data_source.dart';
import '../models/dashboard_models.dart';
import 'dart:io';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;
  final HomeLocalDataSource localDataSource;

  HomeRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<DashboardData> getDashboardData() async {
    try {
      final data = await remoteDataSource.getDashboard();
      await localDataSource.cacheDashboard(data);
      return data;
    } on SocketException {
      return await _fetchLocalData();
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('ClientException')) {
        return await _fetchLocalData();
      }
      rethrow;
    }
  }
  
  Future<DashboardData> _fetchLocalData() async {
    try {
      return await localDataSource.getLastDashboard();
    } catch (e) {
      throw Exception('No internet connection and no cached data available.');
    }
  }
}
