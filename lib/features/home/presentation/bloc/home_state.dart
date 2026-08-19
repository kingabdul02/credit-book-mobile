import '../../domain/entities/dashboard_entities.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final DashboardData dashboardData;

  HomeLoaded(this.dashboardData);
}

class HomeError extends HomeState {
  final String message;

  HomeError(this.message);
}
