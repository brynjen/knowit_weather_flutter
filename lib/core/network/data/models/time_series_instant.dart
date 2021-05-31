import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'time_series_instant.g.dart';

@JsonSerializable()
class TimeSeriesInstant extends Equatable {
  final Map<String, dynamic>? details;

  TimeSeriesInstant(this.details);
  factory TimeSeriesInstant.fromJson(Map<String, dynamic> json) => _$TimeSeriesInstantFromJson(json);
  Map<String, dynamic> toJson() => _$TimeSeriesInstantToJson(this);

  @override
  List<Object?> get props => [details];
}
