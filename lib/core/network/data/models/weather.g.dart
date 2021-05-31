// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Weather _$WeatherFromJson(Map<String, dynamic> json) {
  return Weather(
    json['type'] as String,
    Geometry.fromJson(json['geometry'] as Map<String, dynamic>),
    Properties.fromJson(json['properties'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$WeatherToJson(Weather instance) => <String, dynamic>{
      'type': instance.type,
      'geometry': instance.geometry,
      'properties': instance.properties,
    };
