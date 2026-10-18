import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/services/sync_service.dart';
import '../../domain/repositories/home_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository repository;
  StreamSubscription? _syncSub;

  HomeBloc({required this.repository}) : super(HomeInitial()) {
    on<LoadDashboardRequested>(_onLoadDashboardRequested);
    _syncSub = SyncService.onSyncComplete.listen((_) {
      add(LoadDashboardRequested(forceRefresh: false));
    });
  }

  @override
  Future<void> close() {
    _syncSub?.cancel();
    return super.close();
  }

  Future<void> _onLoadDashboardRequested(
    LoadDashboardRequested event,
    Emitter<HomeState> emit,
  ) async {
    // 1. Check for cached data to display immediately
    final cached = repository.getCachedDashboardData();
    final hasData = state is HomeLoaded || cached != null;

    if (cached != null) {
      // Emit cached data immediately with 0ms delay!
      emit(HomeLoaded(cached));
    } else if (!hasData) {
      // Only emit loading spinner if we have no prior data to display
      emit(HomeLoading());
    }

    try {
      final data = await repository.getDashboardData(forceRefresh: event.forceRefresh);
      emit(HomeLoaded(data));
    } catch (e) {
      if (!hasData) {
        emit(HomeError(ErrorHandler.getFriendlyMessage(e)));
      }
    }
  }
}
