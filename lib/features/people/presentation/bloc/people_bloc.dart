import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/error_handler.dart';
import '../../domain/entities/contact_entity.dart';
import '../../domain/repositories/people_repository.dart';

// Events
abstract class PeopleEvent {}

class LoadPeopleDataRequested extends PeopleEvent {
  final bool forceRefresh;
  LoadPeopleDataRequested({this.forceRefresh = false});
}

// States
abstract class PeopleState {}

class PeopleInitial extends PeopleState {}

class PeopleLoading extends PeopleState {}

class PeopleLoaded extends PeopleState {
  final PeopleDataEntity peopleData;
  PeopleLoaded(this.peopleData);
}

class PeopleError extends PeopleState {
  final String message;
  PeopleError(this.message);
}

// Bloc
class PeopleBloc extends Bloc<PeopleEvent, PeopleState> {
  final PeopleRepository repository;

  PeopleBloc({required this.repository}) : super(PeopleInitial()) {
    on<LoadPeopleDataRequested>(_onLoadPeopleDataRequested);
  }

  Future<void> _onLoadPeopleDataRequested(
    LoadPeopleDataRequested event,
    Emitter<PeopleState> emit,
  ) async {
    // 1. Check for cached people data to render immediately
    final cached = repository.getCachedPeopleData();
    final hasData = state is PeopleLoaded || cached != null;

    if (cached != null && state is! PeopleLoaded) {
      emit(PeopleLoaded(cached));
    } else if (!hasData) {
      emit(PeopleLoading());
    }

    try {
      final data = await repository.getPeopleData(forceRefresh: event.forceRefresh);
      emit(PeopleLoaded(data));
    } catch (e) {
      if (!hasData) {
        emit(PeopleError(ErrorHandler.getFriendlyMessage(e)));
      }
    }
  }
}
