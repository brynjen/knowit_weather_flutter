import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'time_series_summary.dart';

part 'time_series_period.g.dart';

@JsonSerializable()
class TimeSeriesPeriod extends Equatable {
  final TimeSeriesSummary summary;
  TimeSeriesPeriod(this.summary);
  factory TimeSeriesPeriod.fromJson(Map<String, dynamic> json) => _$TimeSeriesPeriodFromJson(json);

  Map<String, dynamic> toJson() => _$TimeSeriesPeriodToJson(this);

  @override
  List<Object?> get props => [summary];
}
