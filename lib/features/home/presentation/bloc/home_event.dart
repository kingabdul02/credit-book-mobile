abstract class HomeEvent {}

class LoadDashboardRequested extends HomeEvent {
  final bool forceRefresh;
  LoadDashboardRequested({this.forceRefresh = false});
}
