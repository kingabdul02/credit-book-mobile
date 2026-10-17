import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/error_handler.dart';
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
    final cached = repository.getCachedInsightsData(event.timeframe);
    final hasData = (state is InsightsLoaded &&
            (state as InsightsLoaded).currentTimeframe.toLowerCase() ==
                event.timeframe.toLowerCase()) ||
        cached != null;

    if (cached != null &&
        (state is! InsightsLoaded ||
            (state as InsightsLoaded).currentTimeframe.toLowerCase() !=
                event.timeframe.toLowerCase())) {
      emit(InsightsLoaded(data: cached, currentTimeframe: event.timeframe));
    } else if (!hasData) {
      emit(InsightsLoading());
    }

    try {
      final data = await repository.getInsightsData(
        event.timeframe,
        forceRefresh: event.forceRefresh,
      );
      emit(InsightsLoaded(data: data, currentTimeframe: event.timeframe));
    } catch (e) {
      if (!hasData) {
        emit(InsightsError(
          ErrorHandler.getFriendlyMessage(e),
          currentTimeframe: event.timeframe,
        ));
      }
    }
  }
}
