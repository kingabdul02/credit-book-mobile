import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/insights_repository.dart';
import 'insights_event.dart';
import 'insights_state.dart';

class InsightsBloc extends Bloc<InsightsEvent, InsightsState> {
  final InsightsRepository repository;

  InsightsBloc({required this.repository}) : super(InsightsInitial()) {
    on<FetchInsightsData>(_onFetchInsightsData);
  }

  Future<void> _onFetchInsightsData(
    FetchInsightsData event,
    Emitter<InsightsState> emit,
  ) async {
    emit(InsightsLoading());
    try {
      final data = await repository.getInsightsData(event.timeframe);
      emit(InsightsLoaded(data: data, currentTimeframe: event.timeframe));
    } catch (e) {
      emit(InsightsError(e.toString(), currentTimeframe: event.timeframe));
    }
  }
}
