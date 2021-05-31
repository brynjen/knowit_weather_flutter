import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'time_series_instant.dart';
import 'time_series_period.dart';

part 'time_series_data.g.dart';

@JsonSerializable()
class TimeSeriesData extends Equatable {
  final TimeSeriesInstant instant;
  @JsonKey(name: 'next_1_hours')
  final TimeSeriesPeriod? next1hours;
  TimeSeriesData(this.instant, this.next1hours);

  factory TimeSeriesData.fromJson(Map<String, dynamic> json) => _$TimeSeriesDataFromJson(json);

  Map<String, dynamic> toJson() => _$TimeSeriesDataToJson(this);

  @override
  List<Object?> get props => [instant, next1hours];
}
