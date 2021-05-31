// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'properties.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Properties _$PropertiesFromJson(Map<String, dynamic> json) {
  return Properties(
    (json['timeseries'] as List<dynamic>)
        .map((e) => TimeSeries.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$PropertiesToJson(Properties instance) =>
    <String, dynamic>{
      'timeseries': instance.timeSeries,
    };
