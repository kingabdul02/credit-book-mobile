import 'package:equatable/equatable.dart';

abstract class InsightsEvent extends Equatable {
  const InsightsEvent();

  @override
  List<Object> get props => [];
}

class FetchInsightsData extends InsightsEvent {
  final String timeframe;
  final bool forceRefresh;

  const FetchInsightsData({
    this.timeframe = 'Weekly',
    this.forceRefresh = false,
  });

  @override
  List<Object> get props => [timeframe, forceRefresh];
}
