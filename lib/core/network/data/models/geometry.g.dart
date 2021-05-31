// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geometry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Geometry _$GeometryFromJson(Map<String, dynamic> json) {
  return Geometry(
    (json['coordinates'] as List<dynamic>)
        .map((e) => (e as num).toDouble())
        .toList(),
  );
}

Map<String, dynamic> _$GeometryToJson(Geometry instance) => <String, dynamic>{
      'coordinates': instance.coordinates,
    };
