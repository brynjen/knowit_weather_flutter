import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'time_series.dart';

part 'properties.g.dart';

@JsonSerializable()
class Properties extends Equatable {
  @JsonKey(name: 'timeseries')
  final List<TimeSeries> timeSeries;

  Properties(this.timeSeries);

  factory Properties.fromJson(Map<String, dynamic> json) => _$PropertiesFromJson(json);

  Map<String, dynamic> toJson() => _$PropertiesToJson(this);

  @override
  List<Object?> get props => [timeSeries];
}
