// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_series_period.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeSeriesPeriod _$TimeSeriesPeriodFromJson(Map<String, dynamic> json) {
  return TimeSeriesPeriod(
    TimeSeriesSummary.fromJson(json['summary'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$TimeSeriesPeriodToJson(TimeSeriesPeriod instance) =>
    <String, dynamic>{
      'summary': instance.summary,
    };
