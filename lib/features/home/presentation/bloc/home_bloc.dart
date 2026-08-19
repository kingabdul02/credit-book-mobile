import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/home_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository repository;

  HomeBloc({required this.repository}) : super(HomeInitial()) {
    on<LoadDashboardRequested>(_onLoadDashboardRequested);
  }

  Future<void> _onLoadDashboardRequested(
    LoadDashboardRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    try {
      final data = await repository.getDashboardData();
      emit(HomeLoaded(data));
    } catch (e) {
      emit(HomeError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
