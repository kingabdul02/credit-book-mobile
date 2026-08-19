import 'package:equatable/equatable.dart';

abstract class InsightsEvent extends Equatable {
  const InsightsEvent();

  @override
  List<Object> get props => [];
}

class FetchInsightsData extends InsightsEvent {
  final String timeframe;

  const FetchInsightsData({this.timeframe = 'Weekly'});

  @override
  List<Object> get props => [timeframe];
}
