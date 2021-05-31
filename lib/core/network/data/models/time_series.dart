import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'time_series_data.dart';

part 'time_series.g.dart';

@JsonSerializable()
class TimeSeries extends Equatable {
  final TimeSeriesData data;
  TimeSeries(this.data);
  factory TimeSeries.fromJson(Map<String, dynamic> json) => _$TimeSeriesFromJson(json);
  Map<String, dynamic> toJson() => _$TimeSeriesToJson(this);

  @override
  List<Object?> get props => [data];
}
