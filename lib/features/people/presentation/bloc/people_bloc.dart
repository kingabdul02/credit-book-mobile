import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/error_handler.dart';
import '../../domain/entities/contact_entity.dart';
import '../../domain/repositories/people_repository.dart';

// Events
abstract class PeopleEvent {}

class LoadPeopleDataRequested extends PeopleEvent {}

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
    emit(PeopleLoading());
    try {
      final data = await repository.getPeopleData();
      emit(PeopleLoaded(data));
    } catch (e) {
      emit(PeopleError(ErrorHandler.getFriendlyMessage(e)));
    }
  }
}
