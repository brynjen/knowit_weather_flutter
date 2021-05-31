// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_series_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeSeriesData _$TimeSeriesDataFromJson(Map<String, dynamic> json) {
  return TimeSeriesData(
    TimeSeriesInstant.fromJson(json['instant'] as Map<String, dynamic>),
    json['next_1_hours'] == null
        ? null
        : TimeSeriesPeriod.fromJson(
            json['next_1_hours'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$TimeSeriesDataToJson(TimeSeriesData instance) =>
    <String, dynamic>{
      'instant': instance.instant,
      'next_1_hours': instance.next1hours,
    };
