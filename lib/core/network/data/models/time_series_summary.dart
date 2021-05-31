import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'time_series_summary.g.dart';

@JsonSerializable()
class TimeSeriesSummary extends Equatable {
  @JsonKey(name: 'symbol_code')
  final String symbolCode;
  TimeSeriesSummary(this.symbolCode);
  factory TimeSeriesSummary.fromJson(Map<String, dynamic> json) => _$TimeSeriesSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$TimeSeriesSummaryToJson(this);

  @override
  List<Object?> get props => [symbolCode];
}
