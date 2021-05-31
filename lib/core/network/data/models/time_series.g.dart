// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_series.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeSeries _$TimeSeriesFromJson(Map<String, dynamic> json) {
  return TimeSeries(
    TimeSeriesData.fromJson(json['data'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$TimeSeriesToJson(TimeSeries instance) =>
    <String, dynamic>{
      'data': instance.data,
    };
