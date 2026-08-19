import 'package:equatable/equatable.dart';
import '../../domain/entities/insights_entity.dart';

abstract class InsightsState extends Equatable {
  const InsightsState();

  @override
  List<Object?> get props => [];
}

class InsightsInitial extends InsightsState {}

class InsightsLoading extends InsightsState {}

class InsightsLoaded extends InsightsState {
  final InsightsDataEntity data;
  final String currentTimeframe;

  const InsightsLoaded({
    required this.data,
    required this.currentTimeframe,
  });

  @override
  List<Object?> get props => [data, currentTimeframe];
}

class InsightsError extends InsightsState {
  final String message;
  final String currentTimeframe;

  const InsightsError(this.message, {this.currentTimeframe = 'monthly'});

  @override
  List<Object?> get props => [message, currentTimeframe];
}
